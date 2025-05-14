const express = require('express');
const morgan = require('morgan');
const cors = require('cors');
const path = require('path');

const app = express();

// Middlewares
app.use(morgan('dev'));
app.use(cors());
app.use(express.json());

// Archivos estáticos
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Rutas
try {
  const usersRoutes = require('./routes/users');
  app.use('/api/users', usersRoutes);
} catch (error) {
  console.error('No se pudo cargar el archivo de rutas users:', error.message);
}

try {
  const resumesRoutes = require('./routes/resumes');
  app.use('/api/resumes', resumesRoutes);
} catch (error) {
  console.error('No se pudo cargar el archivo de rutas resumes:', error.message);
}

try {
  const analysisRoutes = require('./routes/analysis');
  app.use('/api/analysis', analysisRoutes);
} catch (error) {
  console.error('No se pudo cargar el archivo de rutas analysis:', error.message);
}

try {
  const docxRoutes = require('./routes/docx');
  app.use('/api/docx', docxRoutes);
} catch (error) {
  console.error('No se pudo cargar el archivo de rutas docx:', error.message);
}

// Ruta de prueba para verificar el backend
app.get('/', (req, res) => {
  res.send('Servidor Backend CVscanner funcionando correctamente 🚀');
});

// Middleware para rutas no encontradas (404)
app.use((req, res, next) => {
  res.status(404).json({ message: 'Ruta no encontrada' });
});

// Middleware de manejo de errores global
app.use((err, req, res, next) => {
  console.error('Error interno del servidor:', err.stack);
  res.status(500).json({ message: 'Error interno del servidor', error: err.message });
});

module.exports = app;
