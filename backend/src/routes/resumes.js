const { Router } = require('express');
const router = Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const Tesseract = require('tesseract.js');

const Resume = require('../models/Resume');

// Configuramos multer para usar memoria en lugar de disco
const storage = multer.memoryStorage();
const upload = multer({ storage });

// Endpoint para procesar la imagen y extraer texto
router.post('/upload', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No se ha subido ninguna imagen' });
    }

    // Convertir la imagen a base64 para guardarla en la base de datos
    const imageBase64 = req.file.buffer.toString('base64');
    const imageMimeType = req.file.mimetype;
    const imageData = `data:${imageMimeType};base64,${imageBase64}`;
    
    // Si se proporciona un texto combinado, usarlo en lugar de realizar OCR
    let extractedText = '';
    if (req.body.combinedText) {
      extractedText = req.body.combinedText;
    } else {
      // Realizar OCR con Tesseract usando el buffer de la imagen
      const result = await Tesseract.recognize(
        req.file.buffer,
        'spa', // Idioma español, cambia según necesidades
        { logger: info => console.log(info) }
      );
      extractedText = result.data.text;
    }
    
    // Guardar en la base de datos
    const resume = new Resume({
      originalImage: imageData,
      extractedText,
      fileName: req.file.originalname
    });

    await resume.save();

    res.status(200).json({
      message: 'Procesamiento exitoso',
      resume: {
        id: resume._id,
        extractedText
      }
    });
  } catch (error) {
    console.error('Error al procesar la imagen:', error);
    res.status(500).json({ message: 'Error al procesar la imagen', error: error.message });
  }
});

// Endpoint para obtener todos los CV
router.get('/', async (req, res) => {
  try {
    const resumes = await Resume.find().sort({ createdAt: -1 });
    res.json({ resumes });
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener los CVs', error: error.message });
  }
});

// Endpoint para obtener un CV específico
router.get('/:id', async (req, res) => {
  try {
    const resume = await Resume.findById(req.params.id);
    if (!resume) {
      return res.status(404).json({ message: 'CV no encontrado' });
    }
    res.json({ resume });
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener el CV', error: error.message });
  }
});

module.exports = router;