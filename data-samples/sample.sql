-- sample_data.sql
USE campus_wellbeing;

INSERT INTO Students VALUES (1, 'Alice', 20, 'F', 'CSE', 2);
INSERT INTO Students VALUES (2, 'Bob', 21, 'M', 'ECE', 3);
INSERT INTO Students VALUES (3, 'Cara', 24, 'F', 'MBA', 1);

INSERT INTO Courses VALUES (101, 'Data Structures', 4, 'CSE');
INSERT INTO Courses VALUES (102, 'Intro Psychology', 3, 'HUM');
INSERT INTO Courses VALUES (201, 'Statistics', 3, 'MATH');

INSERT INTO Enrollments VALUES (1, 1, 101, '2025-Spring', 'A');
INSERT INTO Enrollments VALUES (2, 1, 102, '2025-Spring', 'B');
INSERT INTO Enrollments VALUES (3, 2, 201, '2025-Spring', 'B');

INSERT INTO CampusServices VALUES (1, 'Main Library', 'Academic', 'Library Building');
INSERT INTO CampusServices VALUES (2, 'Counseling Center', 'Health', 'Student Center');
INSERT INTO CampusServices VALUES (3, 'Fitness Center', 'Wellness', 'Gym');

INSERT INTO ServiceUsage VALUES (1, 1, 1, '2025-03-01', 5, 8);
INSERT INTO ServiceUsage VALUES (2, 2, 2, '2025-03-02', 2, 9);
INSERT INTO ServiceUsage VALUES (3, 3, 3, '2025-03-03', 3, 7);

INSERT INTO WellBeingSurveys VALUES (1, 1, '2025-03-01', 6, 7.5, 8);
INSERT INTO WellBeingSurveys VALUES (2, 2, '2025-03-02', 8, 6.0, 5);
INSERT INTO WellBeingSurveys VALUES (3, 3, '2025-03-03', 5, 8.0, 9);

INSERT INTO ProductivityMetrics VALUES (1, 1, '2025-Spring', 3.80, 95.0, 90.0);
INSERT INTO ProductivityMetrics VALUES (2, 2, '2025-Spring', 3.20, 85.0, 80.0);
INSERT INTO ProductivityMetrics VALUES (3, 3, '2025-Spring', 3.60, 90.0, 85.0);

INSERT INTO CampusEnvironment VALUES (1, 'Library', 55.0, 0.30, 600.0, 8);
INSERT INTO CampusEnvironment VALUES (2, 'Cafeteria', 75.0, 0.80, 350.0, 6);
INSERT INTO CampusEnvironment VALUES (3, 'Gym', 65.0, 0.50, 400.0, 7);
