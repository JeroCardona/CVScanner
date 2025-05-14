const { Router } = require('express');
const router = Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const Tesseract = require('tesseract.js');

const Resume = require('../models/Resume');
const User = require('../models/User');

// Configuramos multer para usar memoria en lugar de disco
const storage = multer.memoryStorage();
const upload = multer({ storage });

// Endpoint para procesar la imagen y guardar el CV con user obtenido por ownerDocument
router.post('/upload', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No se ha subido ninguna imagen' });
    }

    const { ownerDocument, combinedText } = req.body;

    if (!ownerDocument) {
      return res.status(400).json({ message: 'Falta el número de cédula (ownerDocument)' });
    }

    const user = await User.findOne({ document: ownerDocument });
    if (!user) {
      return res.status(404).json({ message: 'Usuario no encontrado con esa cédula' });
    }

    // Convertir la imagen a base64
    const imageBase64 = req.file.buffer.toString('base64');
    const imageMimeType = req.file.mimetype;
    const imageData = `data:${imageMimeType};base64,${imageBase64}`;
    
    let extractedText = '';
    if (combinedText) {
      extractedText = combinedText;
    } else {
      const result = await Tesseract.recognize(
        req.file.buffer,
        'spa',
        { logger: info => console.log(info) }
      );
      extractedText = result.data.text;
    }

    const resume = new Resume({
      user: user._id,
      ownerDocument,
      extractedText,
      originalImage: imageData,
      fileName: req.file.originalname
    });

    await resume.save();

    res.status(201).json({
      message: 'CV guardado exitosamente',
      resume: {
        id: resume._id,
        extractedText
      }
    });
  } catch (error) {
    console.error('Error al procesar el CV:', error);
    res.status(500).json({ message: 'Error interno del servidor', error: error.message });
  }
});
module.exports = router;
