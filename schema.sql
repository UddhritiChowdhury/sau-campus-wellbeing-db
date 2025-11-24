-- Create database
CREATE DATABASE campus_wellbeing;
USE campus_wellbeing;

-- Students table
CREATE TABLE Students (
    student_id INT PRIMARY KEY,
    name VARCHAR(100),
    age INT,
    gender VARCHAR(10),
    program VARCHAR(100),
    year INT,
    contact_info VARCHAR(150)
);

-- Courses table
CREATE TABLE Courses (
    course_id INT PRIMARY KEY,
    course_name VARCHAR(100),
    credits INT,
    department VARCHAR(100)
);

-- Enrollments table (many-to-many Students ↔ Courses)
CREATE TABLE Enrollments (
    enrollment_id INT PRIMARY KEY,
    student_id INT,
    course_id INT,
    semester VARCHAR(20),
    grade VARCHAR(5),
    FOREIGN KEY (student_id) REFERENCES Students(student_id),
    FOREIGN KEY (course_id) REFERENCES Courses(course_id)
);

-- Campus Services table
CREATE TABLE CampusServices (
    service_id INT PRIMARY KEY,
    service_name VARCHAR(100),
    category VARCHAR(50),
    location VARCHAR(100)
);

-- Service Usage table
CREATE TABLE ServiceUsage (
    usage_id INT PRIMARY KEY,
    student_id INT,
    service_id INT,
    date DATE,
    frequency INT,
    satisfaction_rating INT,
    FOREIGN KEY (student_id) REFERENCES Students(student_id),
    FOREIGN KEY (service_id) REFERENCES CampusServices(service_id)
);
