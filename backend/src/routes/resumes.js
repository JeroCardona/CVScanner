const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const Tesseract = require('tesseract.js');

const Resume = require('../models/Resume');
const User = require('../models/User');
const generateResumeDocx = require('../services/generateDocx');
const AIAnalysisService = require('../services/aiAnalysis');
const { getDefaultResultOrder } = require('dns');

const storage = multer.memoryStorage();
const upload = multer({ storage });

router.post('/upload', upload.single('image'), async (req, res) => {
  try {

    if(!req.file) {
      return res.status(400).json({ error: 'No se ha subido ninguna imagen' });
    }

    const { ownerDocument, combinedText } = req.body; // El campo ownerDocument está llegando como "sin_cedula" siempre

    if (!ownerDocument) {
      return res.status(400).json({ message: 'Falta el número de cédula del usuario' });
    }

    console.log('Owner Document:', ownerDocument);
    console.log('Parámetros de req:', req.params);
    console.log('Request completa:', req);

    const user = await User.findOne({ document: ownerDocument });
    
    /*if (!user) {
      return res.status(404).json({ message: 'Usuario no encontrado con el número de cédula proporcionado' }); // Este check no me dejaba avanzar
    }*/                                                                                                        // Porque el usuario "sin_cedula" no existe

    const imageBase64 = req.file.buffer.toString('base64');
    const imageMimeType = req.file.mimetype;
    const imageData = `data:${imageMimeType};base64,${imageBase64}`;

    let extractedText = combinedText || '';

    if (!combinedText || combinedText.trim() === '') {
      // Use Tesseract to extract text from the image if no combinedText is provided
      const { data: { text } } = await Tesseract.recognize(req.file.buffer, 'spa', {
        logger: info => console.log(info)
      });
      extractedText = result.data.text.trim();
    }

    // Analyze with AI and generate PDF
    const analysisResult = await AIAnalysisService.analyzeResume(combinedText);
    
    // Create resume document with your schema structure
    const resumeData = {
      //user: user._id || null,
      ownerDocument: ownerDocument || 'sin_cedula',
      extractedText: extractedText,
      formatted: analysisResult.formatted,
      pdfPath: analysisResult.pdfPath,
      pdfFilename: analysisResult.pdfFilename,
      analysis: {
        message: 'CV processed successfully',
        analyzedAt: new Date()
      }
    };

    if (req.file) {
      resumeData.originalImage = req.file.path;
    }

    const resume = new Resume(resumeData);
    await resume.save();

    res.status(201).json({
      message: 'Resume processed successfully',
      resume: {
        id: resume._id,
        hasPdf: !!analysisResult.pdfPath,
        pdfFilename: analysisResult.pdfFilename
      }
    });

  } catch (error) {
    console.error('Error processing resume:', error);
    res.status(500).json({ 
      error: 'Failed to process resume',
      details: error.message 
    });
  }
});

router.get('/download-pdf/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const resume = await Resume.findById(id);
    
    if (!resume) {
      return res.status(404).json({ error: 'Resume not found' });
    }

    if (!resume.pdfPath || !fs.existsSync(resume.pdfPath)) {
      return res.status(404).json({ error: 'PDF file not found' });
    }

    const filename = resume.pdfFilename || `resume_${resume._id}.pdf`;
    
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    
    const fileStream = fs.createReadStream(resume.pdfPath);
    fileStream.pipe(res);
  } catch (error) {
    console.error('Error downloading PDF:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/download/:id', async (req, res) => {
  try {
    const resume = await Resume.findById(req.params.id);
    if (!resume || !resume.generatedDocxPath) {
      return res.status(404).json({ message: 'Archivo no encontrado para este CV' });
    }

    res.download(resume.generatedDocxPath);
  } catch (error) {
    console.error('Error al descargar el documento:', error);
    res.status(500).json({ message: 'Error interno al intentar descargar', error: error.message });
  }
});

module.exports = router;
