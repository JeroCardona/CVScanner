const express = require('express');
const app = express();
const morgan = require('morgan');
const cors = require('cors');
const path = require('path');

// Middlewares
app.use(morgan('dev'));
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));
const usersRoutes = require('./routes/users');
app.use(usersRoutes);
try {
    const resumesRoutes = require('./routes/resumes');
    app.use('/api/resumes', resumesRoutes);
  } catch (error) {
    console.error('No se pudo cargar el archivo de rutas resumes:', error.message);
  }
module.exports = app;