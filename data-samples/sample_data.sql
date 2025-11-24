INSERT INTO Students VALUES (1, 'Alice', 20, 'F', 'CSE', 2);
INSERT INTO Students VALUES (2, 'Bob', 21, 'M', 'ECE', 3);

INSERT INTO Courses VALUES (101, 'Data Structures', 4, 'CSE');
INSERT INTO Courses VALUES (102, 'Psychology 101', 3, 'Humanities');

INSERT INTO Enrollments VALUES (1, 1, 101, '2025-Spring', 'A');
INSERT INTO Enrollments VALUES (2, 2, 102, '2025-Spring', 'B');

INSERT INTO CampusServices VALUES (1, 'Library', 'Academic', 'Main Building');
INSERT INTO CampusServices VALUES (2, 'Counseling', 'Health', 'Student Center');

INSERT INTO ServiceUsage VALUES (1, 1, 1, '2025-03-01', 5, 8);
INSERT INTO ServiceUsage VALUES (2, 2, 2, '2025-03-02', 2, 9);

INSERT INTO WellBeingSurveys VALUES (1, 1, '2025-03-01', 6, 7.5, 8);
INSERT INTO WellBeingSurveys VALUES (2, 2, '2025-03-02', 8, 6.0, 5);

INSERT INTO ProductivityMetrics VALUES (1, 1, '2025-Spring', 3.8, 95.0, 90.0);
INSERT INTO ProductivityMetrics VALUES (2, 2, '2025-Spring', 3.2, 85.0, 80.0);

INSERT INTO CampusEnvironment VALUES (1, 'Library', 55.0, 0.3, 600.0, 8);
INSERT INTO CampusEnvironment VALUES (2, 'Cafeteria', 75.0, 0.8, 350.0, 6);
