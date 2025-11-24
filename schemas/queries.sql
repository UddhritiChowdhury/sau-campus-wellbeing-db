-- Correlation between service usage and GPA
SELECT s.student_id, AVG(su.satisfaction_rating) AS avg_service_rating, pm.GPA
FROM Students s
JOIN ServiceUsage su ON s.student_id = su.student_id
JOIN ProductivityMetrics pm ON s.student_id = pm.student_id
GROUP BY s.student_id;
