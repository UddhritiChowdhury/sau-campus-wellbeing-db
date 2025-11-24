CREATE DATABASE IF NOT EXISTS mood_tracker;
USE mood_tracker;

--------------------------------------------------------
-- 1. Students
--------------------------------------------------------
CREATE TABLE IF NOT EXISTS students (
    student_id VARCHAR(20) PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    department VARCHAR(50) NOT NULL,
    semester INT NOT NULL,
    age INT,
    gender ENUM('Male','Female','Non-binary','Prefer not to say'),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

--------------------------------------------------------
-- 2. Courses & Enrollment
--------------------------------------------------------
CREATE TABLE IF NOT EXISTS courses (
    course_id VARCHAR(20) PRIMARY KEY,
    course_code VARCHAR(20) NOT NULL,
    title VARCHAR(200) NOT NULL,
    credits DECIMAL(3,1) DEFAULT 3.0,
    department VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS course_sections (
    section_id VARCHAR(20) PRIMARY KEY,
    course_id VARCHAR(20) NOT NULL,
    term VARCHAR(20) NOT NULL,
    instructor VARCHAR(100),
    room VARCHAR(50),
    schedule VARCHAR(100),
    FOREIGN KEY(course_id) REFERENCES courses(course_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS enrollments (
    enrollment_id VARCHAR(20) PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    section_id VARCHAR(20) NOT NULL,
    enrolled_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    grade DECIMAL(4,2),
    UNIQUE(student_id, section_id),
    FOREIGN KEY(student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY(section_id) REFERENCES course_sections(section_id) ON DELETE CASCADE
);

--------------------------------------------------------
-- 3. Campus Factors
--------------------------------------------------------
CREATE TABLE IF NOT EXISTS campus_factors (
    factor_id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(80),
    event_type ENUM('Exam Week','Holiday','Regular Class Day','Sports Event',
                    'Festival','Placement Season','Assignment Deadline'),
    weather ENUM('Sunny','Cloudy','Rainy','Cold','Humid'),
    workload_level TINYINT CHECK(workload_level BETWEEN 1 AND 10)
);

--------------------------------------------------------
-- 4. Services & Appointments
--------------------------------------------------------
CREATE TABLE IF NOT EXISTS services (
    service_id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(50),
    location VARCHAR(150)
);

CREATE TABLE IF NOT EXISTS service_appointments (
    appointment_id VARCHAR(20) PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    service_id VARCHAR(20) NOT NULL,
    scheduled_at DATETIME NOT NULL,
    outcome_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY(service_id) REFERENCES services(service_id) ON DELETE CASCADE
);

--------------------------------------------------------
-- 5. Wellbeing & Counseling
--------------------------------------------------------
CREATE TABLE IF NOT EXISTS wellbeing_surveys (
    survey_id VARCHAR(20) PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    survey_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    stress_level TINYINT CHECK(stress_level BETWEEN 0 AND 10),
    sleep_hours DECIMAL(3,1),
    study_hours DECIMAL(4,2),
    mood VARCHAR(50),
    notes TEXT,
    FOREIGN KEY(student_id) REFERENCES students(student_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS counseling_visits (
    visit_id VARCHAR(20) PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    visit_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    counselor VARCHAR(100),
    reason VARCHAR(200),
    follow_up_needed BOOLEAN DEFAULT FALSE,
    notes TEXT,
    FOREIGN KEY(student_id) REFERENCES students(student_id) ON DELETE CASCADE
);

--------------------------------------------------------
-- 6. Mood & Productivity Logs (Core)
--------------------------------------------------------
CREATE TABLE IF NOT EXISTS mood_logs (
    mood_id VARCHAR(20) PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    mood ENUM('Very Happy','Happy','Neutral','Sad','Stressed','Tired','Angry','Numb','SUICIDAL'),
    stress_level TINYINT CHECK(stress_level BETWEEN 1 AND 10),
    notes TEXT,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    factor_id VARCHAR(20),
    FOREIGN KEY(student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY(factor_id) REFERENCES campus_factors(factor_id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS productivity_logs (
    productivity_id VARCHAR(20) PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    productivity_score TINYINT CHECK(productivity_score BETWEEN 1 AND 10),
    study_hours DECIMAL(4,1),
    sleep_hours DECIMAL(4,1),
    notes TEXT,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    factor_id VARCHAR(20),
    FOREIGN KEY(student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY(factor_id) REFERENCES campus_factors(factor_id) ON DELETE SET NULL
);

--------------------------------------------------------
-- 7. Admins & Interventions
--------------------------------------------------------
CREATE TABLE IF NOT EXISTS admins (
    admin_id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL,
    email VARCHAR(150) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS interventions (
    intervention_id VARCHAR(20) PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    admin_id VARCHAR(20),
    description TEXT NOT NULL,
    action_taken ENUM('Email Sent','Counseling Session','Survey','Follow-up Call','None'),
    follow_up_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY(admin_id) REFERENCES admins(admin_id) ON DELETE SET NULL
);

--------------------------------------------------------
-- 9. Analytics Summary
--------------------------------------------------------
CREATE TABLE IF NOT EXISTS student_daily_summary (
    student_id VARCHAR(20) NOT NULL,
    day DATE NOT NULL,
    avg_productivity DECIMAL(5,2),
    avg_stress DECIMAL(5,2),
    total_study_hours DECIMAL(8,2),
    avg_sleep_hours DECIMAL(4,2),
    PRIMARY KEY(student_id, day),
    FOREIGN KEY(student_id) REFERENCES students(student_id)
);
