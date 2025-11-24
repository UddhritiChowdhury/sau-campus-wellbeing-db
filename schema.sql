this whole code-- Enable required extension
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Students
CREATE TABLE IF NOT EXISTS students (
  student_id       SERIAL PRIMARY KEY,
  full_name        VARCHAR(100) NOT NULL,
  email            VARCHAR(150) UNIQUE,
  department       VARCHAR(50) NOT NULL,
  semester         INT NOT NULL,
  age              INT,
  gender           VARCHAR(30) CHECK (gender IN ('Male','Female','Non-binary','Prefer not to say')),
  created_at       TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 2. Academic structure
CREATE TABLE IF NOT EXISTS courses (
  course_id        SERIAL PRIMARY KEY,
  course_code      VARCHAR(20) NOT NULL,
  title            VARCHAR(200) NOT NULL,
  credits          NUMERIC(3,1) DEFAULT 3.0,
  department       VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS course_sections (
  section_id       SERIAL PRIMARY KEY,
  course_id        INT NOT NULL REFERENCES courses(course_id) ON DELETE CASCADE,
  term             VARCHAR(20) NOT NULL,
  instructor       VARCHAR(100),
  capacity         INT,
  room_id          INT,
  start_time       TIME,
  end_time         TIME,
  days_of_week     VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS enrollments (
  enrollment_id    SERIAL PRIMARY KEY,
  student_id       INT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
  section_id       INT NOT NULL REFERENCES course_sections(section_id) ON DELETE CASCADE,
  enrolled_on      TIMESTAMP WITH TIME ZONE DEFAULT now(),
  grade            NUMERIC(4,2),
  UNIQUE(student_id, section_id)
);

-- 3. Rooms and events
CREATE TABLE IF NOT EXISTS rooms (
  room_id          SERIAL PRIMARY KEY,
  building         VARCHAR(100),
  room_number      VARCHAR(50),
  capacity         INT
);

CREATE TABLE IF NOT EXISTS campus_events (
  event_id         SERIAL PRIMARY KEY,
  title            VARCHAR(200) NOT NULL,
  description      TEXT,
  location_room_id INT REFERENCES rooms(room_id),
  start_ts         TIMESTAMP WITH TIME ZONE NOT NULL,
  end_ts           TIMESTAMP WITH TIME ZONE NOT NULL,
  organizer        VARCHAR(100)
);

-- 4. Campus factors
CREATE TABLE IF NOT EXISTS campus_factors (
  factor_id    SERIAL PRIMARY KEY,
  name         VARCHAR(150) NOT NULL,
  category     VARCHAR(80),
  description  TEXT,
  event_type   VARCHAR(80) CHECK (event_type IN (
                 'Exam Week','Holiday','Regular Class Day','Sports Event','Festival','Placement Season','Assignment Deadline')) ,
  weather      VARCHAR(20) CHECK (weather IN ('Sunny','Cloudy','Rainy','Cold','Humid')),
  workload_level SMALLINT CHECK (workload_level BETWEEN 1 AND 10)
);

-- 5. Campus services and appointments
CREATE TABLE IF NOT EXISTS services (
  service_id       SERIAL PRIMARY KEY,
  name             VARCHAR(150) NOT NULL,
  category         VARCHAR(50),
  location         VARCHAR(150)
);

CREATE TABLE IF NOT EXISTS service_appointments (
  appointment_id   BIGSERIAL PRIMARY KEY,
  student_id       INT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
  service_id       INT NOT NULL REFERENCES services(service_id) ON DELETE CASCADE,
  staff_member     VARCHAR(100),
  scheduled_at     TIMESTAMP WITH TIME ZONE NOT NULL,
  duration_minutes INT,
  outcome_notes    TEXT,
  created_at       TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 6. Wellbeing surveys and counseling visits
CREATE TABLE IF NOT EXISTS wellbeing_surveys (
  survey_id        BIGSERIAL PRIMARY KEY,
  student_id       INT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
  survey_ts        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  stress_level     SMALLINT CHECK (stress_level BETWEEN 0 AND 10),
  sleep_hours      NUMERIC(3,1),
  study_hours      NUMERIC(4,2),
  mood             VARCHAR(50),
  notes_encrypted  BYTEA
);

CREATE TABLE IF NOT EXISTS counseling_visits (
  visit_id         BIGSERIAL PRIMARY KEY,
  student_id       INT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
  visit_ts         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  counselor        VARCHAR(100),
  reason           VARCHAR(200),
  follow_up_needed BOOLEAN DEFAULT FALSE,
  notes_encrypted  BYTEA
);

-- 7. Sensors and environmental readings
CREATE TABLE IF NOT EXISTS sensors (
  sensor_id        SERIAL PRIMARY KEY,
  sensor_name      VARCHAR(150),
  sensor_type      VARCHAR(50),
  building         VARCHAR(100),
  room_id          INT REFERENCES rooms(room_id),
  installed_on     DATE
);

CREATE TABLE IF NOT EXISTS sensor_readings (
  reading_id       BIGSERIAL PRIMARY KEY,
  sensor_id        INT NOT NULL REFERENCES sensors(sensor_id) ON DELETE CASCADE,
  reading_ts       TIMESTAMP WITH TIME ZONE NOT NULL,
  numeric_value    NUMERIC(10,4),
  unit             VARCHAR(20),
  meta             JSONB
);

-- 8. Passive presence logs
CREATE TABLE IF NOT EXISTS presence_logs (
  log_id           BIGSERIAL PRIMARY KEY,
  student_id       INT REFERENCES students(student_id),
  device_id        VARCHAR(100),
  seen_ts          TIMESTAMP WITH TIME ZONE NOT NULL,
  building         VARCHAR(100),
  room_id          INT,
  source           VARCHAR(50)
);

-- 9. Mood logs
CREATE TABLE IF NOT EXISTS mood_logs (
  mood_id      BIGSERIAL PRIMARY KEY,
  student_id   INT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
  mood         VARCHAR(30) NOT NULL CHECK (mood IN ('Very Happy','Happy','Neutral','Sad','Stressed','Tired','Angry')),
  stress_level SMALLINT NOT NULL CHECK (stress_level BETWEEN 1 AND 10),
  note_encrypted BYTEA,
  logged_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  factor_id    INT REFERENCES campus_factors(factor_id) ON DELETE SET NULL,
  source       VARCHAR(50) DEFAULT 'self-report',
  created_by   VARCHAR(100)
);

-- 10. Productivity logs
CREATE TABLE IF NOT EXISTS productivity_logs (
  productivity_id BIGSERIAL PRIMARY KEY,
  student_id      INT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
  productivity_score SMALLINT NOT NULL CHECK (productivity_score BETWEEN 1 AND 10),
  study_hours     NUMERIC(4,1),
  sleep_hours     NUMERIC(4,1),
  notes_encrypted BYTEA,
  logged_at       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  factor_id       INT REFERENCES campus_factors(factor_id) ON DELETE SET NULL,
  source          VARCHAR(50) DEFAULT 'self-report',
  device_id       VARCHAR(100)
);

-- 11. Admins and interventions
CREATE TABLE IF NOT EXISTS admins (
  admin_id    SERIAL PRIMARY KEY,
  name        VARCHAR(100) NOT NULL,
  role        VARCHAR(50) NOT NULL,
  email       VARCHAR(150) UNIQUE,
  phone       VARCHAR(30),
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS interventions (
  intervention_id  BIGSERIAL PRIMARY KEY,
  student_id       INT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
  admin_id         INT REFERENCES admins(admin_id) ON DELETE SET NULL,
  description_encrypted BYTEA NOT NULL,
  action_taken     VARCHAR(40) CHECK (action_taken IN ('Email Sent','Counseling Session','Survey','Follow-up Call','None')),
  outcome_encrypted BYTEA,
  follow_up_date   DATE,
  created_at       TIMESTAMP WITH TIME ZONE DEFAULT now(),
  recorded_by      VARCHAR(100),
  confidential     BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS intervention_tags (
  tag_id    SERIAL PRIMARY KEY,
  name      VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS intervention_tag_map (
  intervention_id BIGINT NOT NULL REFERENCES interventions(intervention_id) ON DELETE CASCADE,
  tag_id          INT NOT NULL REFERENCES intervention_tags(tag_id) ON DELETE CASCADE,
  PRIMARY KEY (intervention_id, tag_id)
);

-- 12. Analytics schema table for precomputed aggregates
CREATE SCHEMA IF NOT EXISTS analytics;

CREATE TABLE IF NOT EXISTS analytics.student_daily (
  student_id INT NOT NULL,
  day DATE NOT NULL,
  avg_productivity NUMERIC(5,2),
  avg_stress NUMERIC(5,2),
  total_study_hours NUMERIC(8,2),
  avg_sleep_hours NUMERIC(4,2),
  prod_samples INT,
  mood_samples INT,
  PRIMARY KEY (student_id, day)
);
