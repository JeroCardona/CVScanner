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
app.use('/api/users', usersRoutes); 

try {
  const resumesRoutes = require('./routes/resumes');
  app.use('/api/resumes', resumesRoutes);
} catch (error) {
  console.error('No se pudo cargar el archivo de rutas resumes:', error.message);
}

// Ruta de prueba para verificar el backend
app.get('/', (req, res) => {
  res.send('Servidor Backend CVScanner funcionando correctamente 🚀');
});

// Middleware para rutas no encontradas
app.use((req, res) => {
  res.status(404).json({ message: 'Ruta no encontrada' });
});

// Middleware de manejo de errores global
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Error interno del servidor', error: err.message });
});

module.exports = app;
