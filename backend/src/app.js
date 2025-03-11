const express = require('express');
const app = express();
const morgan = require('morgan');
const cors = require('cors');
const path = require('path');

// Middlewares
app.use(morgan('dev'));
app.use(cors());
app.use(express.json());

// Archivos estáticos
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Montar las rutas con prefijo
const usersRoutes = require('./routes/users');
app.use('/api/users', usersRoutes); // Añadido el prefijo /api/users

try {
  const resumesRoutes = require('./routes/resumes');
  app.use('/api/resumes', resumesRoutes); // Prefijo para las rutas de resumes
} catch (error) {
  console.error('No se pudo cargar el archivo de rutas resumes:', error.message);
}

module.exports = app;
