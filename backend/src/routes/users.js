const express = require('express');
const bcrypt = require('bcryptjs'); // Importar bcrypt para el hash de contraseñas
const router = express.Router();
const User = require('../models/User');

// POST /api/users → Registrar nuevo usuario
router.post('/', async (req, res) => {
  try {
    const { firstName, lastName, phone, document, email, password, confirmPassword } = req.body;

    console.log('Datos recibidos:', req.body); // Verificar qué datos llegan

    // Verificar que todos los campos estén presentes
    if (!firstName || !lastName || !phone || !document || !email || !password || !confirmPassword) {
      return res.status(400).json({ message: 'Por favor, completa todos los campos' });
    }

    // Validar que la contraseña tenga mínimo 8 caracteres
    if (password.length < 8) {
      return res.status(400).json({ message: 'La contraseña debe tener al menos 8 caracteres' });
    }

    // Validar que las contraseñas coincidan
    if (password !== confirmPassword) {
      return res.status(400).json({ message: 'Las contraseñas no coinciden' });
    }

    // Verificar si el email o documento ya están en uso
    const existingUser = await User.findOne({ $or: [{ email }, { document }] });
    if (existingUser) {
      return res.status(400).json({ message: 'El correo electrónico o documento ya está en uso' });
    }

    // Hash de la contraseña antes de guardar
    const hashedPassword = await bcrypt.hash(password, 10);

    // Crear y guardar el usuario en MongoDB
    const newUser = new User({ firstName, lastName, phone, document, email, password: hashedPassword });
    await newUser.save();

    res.status(201).json({ message: 'Usuario registrado exitosamente' });

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error del servidor', error: error.message });
  }
});

// POST /api/users/login → Iniciar sesión de usuario
router.post('/login', async (req, res) => {
  console.log("Datos recibidos en el backend:", req.body);
  
  try {
    console.log("Datos recibidos en login:", req.body);

    const { document, password } = req.body;

    if (!document || !password) {
      return res.status(400).json({ message: 'Por favor, ingresa tu documento y contraseña' });
    }

    const user = await User.findOne({ document });
    if (!user) {
      return res.status(400).json({ message: 'Usuario no encontrado' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Contraseña incorrecta' });
    }

    res.status(200).json({ message: 'Inicio de sesión exitoso' });

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error del servidor', error: error.message });
  }
});

// GET /api/users → Listar todos los usuarios
router.get('/', async (req, res) => {
  try {
    const users = await User.find();
    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener usuarios', error: error.message });
  }
});

module.exports = router;
