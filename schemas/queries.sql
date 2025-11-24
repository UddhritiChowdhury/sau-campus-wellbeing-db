-- ============================================================================
-- campus_wellbeing_queries.sql
-- Single-file collection of queries for the campus well-being schema
-- Replace placeholders like :student_id, :KEY, :term_start with real values.
-- ============================================================================

-- =========================
-- 0. Quick notes
-- =========================
-- Many queries assume the schema and tables from the unified DDL exist:
-- students, courses, course_sections, enrollments, rooms, campus_events,
-- campus_factors, services, service_appointments, wellbeing_surveys,
-- counseling_visits, sensors, sensor_readings, presence_logs, mood_logs,
-- productivity_logs, admins, interventions, analytics.student_daily, mv_student_daily.
-- For decryption queries, the application must set the session key:
--   SET app.encryption_key = 'REPLACE_WITH_SECRET';
-- Do NOT hardcode secrets in production.

-- =========================
-- 1. CRUD and common lookups
-- =========================

-- 1.1 Create a new student
-- Use parameter binding in your app for :full_name, :email, etc.
INSERT INTO students (full_name, email, department, semester, age, gender)
VALUES (:full_name, :email, :department, :semester, :age, :gender)
RETURNING student_id;

-- 1.2 Read student profile with today's aggregates
SELECT s.student_id, s.full_name, s.email, s.department, s.semester, s.age, s.gender,
       a.avg_productivity, a.avg_stress
FROM students s
LEFT JOIN analytics.student_daily a ON a.student_id = s.student_id AND a.day = current_date
WHERE s.student_id = :student_id;

-- 1.3 Update student contact
UPDATE students
SET email = :email, department = :department
WHERE student_id = :student_id;

-- 1.4 Soft-delete (mark inactive)
ALTER TABLE IF NOT EXISTS students ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
UPDATE students SET is_active = FALSE WHERE student_id = :student_id;

-- =========================
-- 2. Service and intervention workflows
-- =========================

-- 2.1 Schedule a service appointment
INSERT INTO service_appointments (student_id, service_id, staff_member, scheduled_at, duration_minutes, outcome_notes)
VALUES (:student_id, :service_id, :staff_member, :scheduled_at, :duration_minutes, :outcome_notes)
RETURNING appointment_id;

-- 2.2 Record an intervention (application must set session key)
-- SET app.encryption_key = :KEY;
INSERT INTO interventions (student_id, admin_id, description_plain, action_taken, outcome_plain, follow_up_date, recorded_by, confidential)
VALUES (:student_id, :admin_id, :description_plain, :action_taken, :outcome_plain, :follow_up_date, :recorded_by, :confidential)
RETURNING intervention_id;

-- 2.3 List recent (public) interventions for a student
SELECT intervention_id, admin_id, action_taken, follow_up_date, created_at
FROM vw_interventions_public
WHERE student_id = :student_id
ORDER BY created_at DESC
LIMIT 50;

-- =========================
-- 3. Top 10 KPI queries (ready for dashboards)
-- =========================

-- KPI 1: Average productivity and stress by department (last 30 days)
SELECT s.department,
       ROUND(AVG(pl.productivity_score)::numeric,2) AS avg_productivity,
       ROUND(AVG(ml.stress_level)::numeric,2) AS avg_stress,
       COUNT(DISTINCT pl.student_id) AS students_reporting
FROM students s
LEFT JOIN productivity_logs pl ON pl.student_id = s.student_id AND pl.logged_at >= now() - INTERVAL '30 days'
LEFT JOIN mood_logs ml ON ml.student_id = s.student_id AND ml.logged_at >= now() - INTERVAL '30 days'
GROUP BY s.department
ORDER BY avg_productivity DESC;

-- KPI 2: Service utilization impact on grades (term)
WITH svc AS (
  SELECT student_id, COUNT(*) AS appointments
  FROM service_appointments
  WHERE scheduled_at >= :term_start AND scheduled_at < :term_end
  GROUP BY student_id
)
SELECT CASE WHEN appointments = 0 THEN '0' WHEN appointments BETWEEN 1 AND 2 THEN '1-2' ELSE '3+' END AS usage_bucket,
       ROUND(AVG(e.grade)::numeric,2) AS avg_grade,
       COUNT(DISTINCT e.student_id) AS students
FROM svc
JOIN enrollments e ON e.student_id = svc.student_id
WHERE e.enrolled_on >= :term_start
GROUP BY usage_bucket
ORDER BY usage_bucket;

-- KPI 3: Students with rising stress trend (7-day rolling increase)
WITH daily_stress AS (
  SELECT student_id, date_trunc('day', logged_at)::date AS day, AVG(stress_level) AS avg_stress
  FROM mood_logs
  WHERE logged_at >= now() - INTERVAL '30 days'
  GROUP BY student_id, date_trunc('day', logged_at)
),
trend AS (
  SELECT student_id, day,
         avg_stress,
         avg_stress - LAG(avg_stress, 7) OVER (PARTITION BY student_id ORDER BY day) AS delta_7d
  FROM daily_stress
)
SELECT student_id, day, ROUND(avg_stress::numeric,2) AS avg_stress, ROUND(delta_7d::numeric,2) AS delta_7d
FROM trend
WHERE delta_7d IS NOT NULL AND delta_7d > 1.5
ORDER BY delta_7d DESC
LIMIT 200;

-- KPI 4: Correlate room noise with study hours (last 30 days)
WITH room_noise AS (
  SELECT r.room_id, date_trunc('day', sr.reading_ts)::date AS day,
         AVG(sr.numeric_value) FILTER (WHERE sr.unit = 'dB') AS avg_noise_db
  FROM sensor_readings sr
  JOIN sensors s ON s.sensor_id = sr.sensor_id
  JOIN rooms r ON r.room_id = s.room_id
  WHERE s.sensor_type = 'noise' AND sr.reading_ts >= now() - INTERVAL '30 days'
  GROUP BY r.room_id, date_trunc('day', sr.reading_ts)
),
student_room_day AS (
  SELECT student_id, room_id, date_trunc('day', seen_ts)::date AS day
  FROM presence_logs
  WHERE seen_ts >= now() - INTERVAL '30 days'
)
SELECT rn.day,
       ROUND(AVG(rn.avg_noise_db)::numeric,2) AS avg_noise_db,
       ROUND(AVG(ws.study_hours)::numeric,2) AS avg_study_hours
FROM room_noise rn
JOIN student_room_day pr ON pr.room_id = rn.room_id AND pr.day = rn.day
JOIN wellbeing_surveys ws ON ws.student_id = pr.student_id AND date_trunc('day', ws.survey_ts)::date = rn.day
GROUP BY rn.day
ORDER BY rn.day DESC
LIMIT 30;

-- KPI 5: Intervention effectiveness — avg productivity before vs after intervention
WITH before_after AS (
  SELECT i.intervention_id, i.student_id, i.created_at,
         (SELECT AVG(productivity_score) FROM productivity_logs pl WHERE pl.student_id = i.student_id AND pl.logged_at BETWEEN i.created_at - INTERVAL '14 days' AND i.created_at - INTERVAL '1 second') AS avg_before,
         (SELECT AVG(productivity_score) FROM productivity_logs pl WHERE pl.student_id = i.student_id AND pl.logged_at BETWEEN i.created_at + INTERVAL '1 second' AND i.created_at + INTERVAL '14 days') AS avg_after
  FROM interventions i
  WHERE i.created_at >= now() - INTERVAL '180 days'
)
SELECT ROUND(AVG(avg_before)::numeric,2) AS campus_avg_before, ROUND(AVG(avg_after)::numeric,2) AS campus_avg_after, COUNT(*) AS interventions_sample
FROM before_after
WHERE avg_before IS NOT NULL OR avg_after IS NOT NULL;

-- KPI 6: Average stress by campus factor (last 30 days)
SELECT cf.name AS factor, ROUND(AVG(ml.stress_level)::numeric,2) AS avg_stress, COUNT(*) AS samples
FROM mood_logs ml
LEFT JOIN campus_factors cf ON cf.factor_id = ml.factor_id
WHERE ml.logged_at >= now() - INTERVAL '30 days'
GROUP BY cf.name
ORDER BY avg_stress DESC;

-- KPI 7: Productivity distribution by sleep bracket (last 30 days)
SELECT
  CASE
    WHEN sleep_hours IS NULL THEN 'unknown'
    WHEN sleep_hours < 5 THEN '<5'
    WHEN sleep_hours BETWEEN 5 AND 6.9 THEN '5-6.9'
    WHEN sleep_hours BETWEEN 7 AND 8.9 THEN '7-8.9'
    ELSE '9+'
  END AS sleep_bucket,
  ROUND(AVG(productivity_score)::numeric,2) AS avg_productivity,
  COUNT(*) AS samples
FROM productivity_logs
WHERE logged_at >= now() - INTERVAL '30 days'
GROUP BY sleep_bucket
ORDER BY avg_productivity DESC;

-- KPI 8: Top 10 rooms by average occupancy (presence logs last 30 days)
SELECT building, room_id, COUNT(*)::int AS presence_count
FROM presence_logs
WHERE seen_ts >= now() - INTERVAL '30 days'
GROUP BY building, room_id
ORDER BY presence_count DESC
LIMIT 10;

-- KPI 9: Counseling uptake and average stress change (students who had counseling)
WITH had_counseling AS (
  SELECT DISTINCT student_id FROM counseling_visits WHERE visit_ts >= now() - INTERVAL '90 days'
),
stress_before_after AS (
  SELECT hv.student_id,
         (SELECT AVG(stress_level) FROM mood_logs ml WHERE ml.student_id = hv.student_id AND ml.logged_at < (SELECT MIN(visit_ts) FROM counseling_visits cv WHERE cv.student_id = hv.student_id) AND ml.logged_at >= now() - INTERVAL '180 days') AS avg_before,
         (SELECT AVG(stress_level) FROM mood_logs ml WHERE ml.student_id = hv.student_id AND ml.logged_at > (SELECT MIN(visit_ts) FROM counseling_visits cv WHERE cv.student_id = hv.student_id) AND ml.logged_at <= now()) AS avg_after
  FROM had_counseling hv
)
SELECT ROUND(AVG(avg_before)::numeric,2) AS avg_before, ROUND(AVG(avg_after)::numeric,2) AS avg_after, COUNT(*) AS students_sample
FROM stress_before_after
WHERE avg_before IS NOT NULL OR avg_after IS NOT NULL;

-- KPI 10: Average time-to-follow-up for interventions by admin (last 180 days)
SELECT a.admin_id, a.name,
       ROUND(AVG(EXTRACT(EPOCH FROM (i.follow_up_date::timestamp - i.created_at))/86400)::numeric,2) AS avg_days_to_follow_up,
       COUNT(*) AS samples
FROM interventions i
LEFT JOIN admins a ON a.admin_id = i.admin_id
WHERE i.follow_up_date IS NOT NULL AND i.created_at >= now() - INTERVAL '180 days'
GROUP BY a.admin_id, a.name
ORDER BY avg_days_to_follow_up NULLS LAST;

-- =========================
-- 4. Privacy, decryption, and restricted access
-- =========================

-- 4.1 Decrypt an encrypted notes field for authorized session
-- Application must set session key first:
--   SET app.encryption_key = :KEY;
SELECT productivity_id, student_id, productivity_score,
       decrypt_text_sym(notes_encrypted, current_setting('app.encryption_key')) AS notes_plain
FROM productivity_logs
WHERE productivity_id = :productivity_id;

-- 4.2 Decrypt intervention description/outcome for authorized user
-- SET app.encryption_key = :KEY;
SELECT intervention_id, student_id, admin_id,
       decrypt_text_sym(description_encrypted, current_setting('app.encryption_key')) AS description_plain,
       action_taken,
       decrypt_text_sym(outcome_encrypted, current_setting('app.encryption_key')) AS outcome_plain,
       follow_up_date, created_at
FROM interventions
WHERE intervention_id = :intervention_id;

-- 4.3 Example: enable row-level security and policy for interventions
ALTER TABLE IF EXISTS interventions ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS interventions_counselor_policy ON interventions
  FOR SELECT USING (confidential = FALSE OR current_setting('app.user_role', true) = 'counselor');

-- =========================
-- 5. Maintenance and operational queries
-- =========================

-- 5.1 Refresh materialized view and upsert into analytics table
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_student_daily;

INSERT INTO analytics.student_daily (student_id, day, avg_productivity, avg_stress, total_study_hours, avg_sleep_hours, prod_samples, mood_samples)
SELECT student_id, day, avg_productivity, avg_stress, total_study_hours, avg_sleep_hours, prod_samples, mood_samples
FROM mv_student_daily
ON CONFLICT (student_id, day) DO UPDATE
SET avg_productivity = EXCLUDED.avg_productivity,
    avg_stress = EXCLUDED.avg_stress,
    total_study_hours = EXCLUDED.total_study_hours,
    avg_sleep_hours = EXCLUDED.avg_sleep_hours,
    prod_samples = EXCLUDED.prod_samples,
    mood_samples = EXCLUDED.mood_samples;

-- 5.2 Partitioning example (create monthly partition for sensor_readings)
-- Note: sensor_readings must be created as a partitioned table for this to work.
-- CREATE TABLE sensor_readings ( ... ) PARTITION BY RANGE (reading_ts);
-- Then create partitions like:
CREATE TABLE IF NOT EXISTS sensor_readings_2025_11 PARTITION OF sensor_readings
  FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

-- 5.3 Rebuild index concurrently
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_sensor_readings_ts_new ON sensor_readings(sensor_id, reading_ts);

-- 5.4 Audit read of confidential intervention (example insert into audit table)
CREATE TABLE IF NOT EXISTS analytics.access_audit (
  audit_id SERIAL PRIMARY KEY,
  actor VARCHAR(200),
  object_type VARCHAR(100),
  object_id BIGINT,
  action VARCHAR(100),
  ts TIMESTAMP WITH TIME ZONE DEFAULT now()
);
INSERT INTO analytics.access_audit (actor, object_type, object_id, action)
VALUES (:actor, 'intervention', :intervention_id, 'read_confidential');

-- =========================
-- 6. Prepared statements and stored procedures (examples)
-- =========================

-- 6.1 Prepared statement: get student daily summary
PREPARE get_student_daily(INT, DATE) AS
SELECT * FROM analytics.student_daily WHERE student_id = $1 AND day = $2;

-- Example execute:
-- EXECUTE get_student_daily(:student_id, :day);

-- 6.2 Stored procedure: upsert analytics for a single student/day
CREATE OR REPLACE FUNCTION analytics.upsert_student_daily(p_student_id INT, p_day DATE)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO analytics.student_daily (student_id, day, avg_productivity, avg_stress, total_study_hours, avg_sleep_hours, prod_samples, mood_samples)
  SELECT student_id, day, avg_productivity, avg_stress, total_study_hours, avg_sleep_hours, prod_samples, mood_samples
  FROM mv_student_daily
  WHERE student_id = p_student_id AND day = p_day
  ON CONFLICT (student_id, day) DO UPDATE
  SET avg_productivity = EXCLUDED.avg_productivity,
      avg_stress = EXCLUDED.avg_stress,
      total_study_hours = EXCLUDED.total_study_hours,
      avg_sleep_hours = EXCLUDED.avg_sleep_hours,
      prod_samples = EXCLUDED.prod_samples,
      mood_samples = EXCLUDED.mood_samples;
END;
$$;

-- Call example:
-- SELECT analytics.upsert_student_daily(:student_id, :day);

-- =========================
-- 7. Example dashboard endpoints (parameterized queries)
-- =========================

-- 7.1 Department summary (last 7 days)
PREPARE dept_summary(TEXT) AS
SELECT s.department,
       ROUND(AVG(pl.productivity_score)::numeric,2) AS avg_productivity,
       ROUND(AVG(ml.stress_level)::numeric,2) AS avg_stress,
       COUNT(DISTINCT s.student_id) AS students_reporting
FROM students s
LEFT JOIN productivity_logs pl ON pl.student_id = s.student_id AND pl.logged_at >= now() - INTERVAL '7 days'
LEFT JOIN mood_logs ml ON ml.student_id = s.student_id AND ml.logged_at >= now() - INTERVAL '7 days'
WHERE s.department = $1
GROUP BY s.department;

-- Execute:
-- EXECUTE dept_summary('CS');

-- 7.2 Student timeline (last 30 days) — combined mood and productivity
PREPARE student_timeline(INT) AS
SELECT date_trunc('day', logged_at)::date AS day,
       AVG(productivity_score) FILTER (WHERE logged_at IS NOT NULL) AS avg_productivity,
       AVG(stress_level) FILTER (WHERE logged_at IS NOT NULL) AS avg_stress,
       SUM(study_hours) FILTER (WHERE logged_at IS NOT NULL) AS total_study_hours
FROM (
  SELECT student_id, logged_at, productivity_score, NULL::INT AS stress_level, study_hours FROM productivity_logs
  UNION ALL
  SELECT student_id, logged_at, NULL::SMALLINT AS productivity_score, stress_level, NULL::NUMERIC AS study_hours FROM mood_logs
) t
WHERE student_id = $1 AND logged_at >= now() - INTERVAL '30 days'
GROUP BY date_trunc('day', logged_at)
ORDER BY day DESC;

-- Execute:
-- EXECUTE student_timeline(:student_id);

-- ============================================================================
-- End of file
-- ============================================================================
