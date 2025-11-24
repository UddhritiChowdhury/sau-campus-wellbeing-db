js
const express = require('express');
const cors = require('cors');
const studentsRouter = require('./routes/students');
const servicesRouter = require('./routes/services');
const envRouter = require('./routes/environment');

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api/students', studentsRouter);
app.use('/api/services', servicesRouter);
app.use('/api/environment', envRouter);

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => console.log(`API listening on ${PORT}`));
