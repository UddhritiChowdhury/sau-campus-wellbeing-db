js
const express = require('express');
const db = require('../db');
const router = express.Router();

router.get('/locations', async (req, res) => {
  try {
    const q = 'SELECT * FROM CampusEnvironment ORDER BY env_id';
    const result = await db.query(q);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
