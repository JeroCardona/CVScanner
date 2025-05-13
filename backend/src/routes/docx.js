const express = require('express');
const path = require('path');
const fs = require('fs');
const generateResumeDocx = require('../services/generateDocx');

const router = express.Router();

router.post('/generate', async (req, res) => {
  try {
    const data = req.body;

    if (!data || !data.documentoIdentidad) {
      return res.status(400).json({ message: 'Falta el documento de identidad' });
    }

    const outputDir = path.resolve(__dirname, '../output');
    if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir);

    const outputPath = path.join(outputDir, `cv_${data.documentoIdentidad}.docx`);

    generateResumeDocx(data, outputPath);

    res.status(200).json({
      message: 'Documento generado exitosamente',
      filePath: outputPath,
    });
  } catch (error) {
    console.error('Error al generar el documento:', error);
    res.status(500).json({ message: 'Error al generar el documento', error: error.message });
  }
});

module.exports = router;
