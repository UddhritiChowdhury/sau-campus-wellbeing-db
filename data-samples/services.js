js
const express = require('express');
const db = require('../db');
const router = express.Router();

router.get('/', async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM CampusServices ORDER BY service_id');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/usage/summary', async (req, res) => {
  try {
    const q = `
      SELECT cs.service_id, cs.service_name, COUNT(su.usage_id) AS visits, AVG(su.satisfaction_rating) AS avg_rating
      FROM CampusServices cs
      LEFT JOIN ServiceUsage su ON cs.service_id = su.service_id
      GROUP BY cs.service_id, cs.service_name
      ORDER BY visits DESC;
    `;
    const result = await db.query(q);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

