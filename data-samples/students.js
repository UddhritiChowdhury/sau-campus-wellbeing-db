js
const express = require('express');
const db = require('../db');
const router = express.Router();

// GET /api/students
router.get('/', async (req, res) => {
  try {
    const result = await db.query('SELECT student_id, name, program, year FROM Students ORDER BY student_id');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/students/:id/profile
router.get('/:id/profile', async (req, res) => {
  const id = req.params.id;
  try {
    const student = await db.query('SELECT * FROM Students WHERE student_id = $1', [id]);
    const surveys = await db.query('SELECT * FROM WellBeingSurveys WHERE student_id = $1 ORDER BY date DESC', [id]);
    const metrics = await db.query('SELECT * FROM ProductivityMetrics WHERE student_id = $1 ORDER BY semester DESC', [id]);
    const usage = await db.query('SELECT su.*, cs.service_name FROM ServiceUsage su JOIN CampusServices cs ON su.service_id = cs.service_id WHERE su.student_id = $1 ORDER BY date DESC', [id]);
    res.json({
      student: student.rows[0] || null,
      surveys: surveys.rows,
      metrics: metrics.rows,
      usage: usage.rows
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
