const { Router } = require('express');
const router = Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const Tesseract = require('tesseract.js');
const PDFDocument = require('pdfkit');
const docx = require('docx');
const { Document, Packer, Paragraph, TextRun } = docx;

const Resume = require('../models/Resume');

// Configurar almacenamiento para las imágenes
const storage = multer.diskStorage({
  destination: function(req, file, cb) {
    const uploadDir = path.join(__dirname, '../../uploads/images');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: function(req, file, cb) {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});

const upload = multer({ storage });

// Configurar directorios para documentos generados
const pdfDir = path.join(__dirname, '../../uploads/pdfs');
const docxDir = path.join(__dirname, '../../uploads/docx');

if (!fs.existsSync(pdfDir)) {
  fs.mkdirSync(pdfDir, { recursive: true });
}

if (!fs.existsSync(docxDir)) {
  fs.mkdirSync(docxDir, { recursive: true });
}

// Endpoint para procesar la imagen y extraer texto
router.post('/upload', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No se ha subido ninguna imagen' });
    }

    const imagePath = req.file.path;
    
    // Realizar OCR con Tesseract
    const result = await Tesseract.recognize(
      imagePath,
      'spa', // Idioma español, cambia según necesidades
      { logger: info => console.log(info) }
    );

    const extractedText = result.data.text;
    
    // Generar PDF
    const pdfFilename = `${Date.now()}_resume.pdf`;
    const pdfPath = path.join(pdfDir, pdfFilename);
    
    const doc = new PDFDocument();
    doc.pipe(fs.createWriteStream(pdfPath));
    doc.fontSize(12).text(extractedText);
    doc.end();

    // Generar DOCX
    const docxFilename = `${Date.now()}_resume.docx`;
    const docxPath = path.join(docxDir, docxFilename);
    
    const document = new Document({
      sections: [{
        properties: {},
        children: [
          new Paragraph({
            children: [
              new TextRun(extractedText)
            ]
          })
        ]
      }]
    });

    const buffer = await Packer.toBuffer(document);
    fs.writeFileSync(docxPath, buffer);

    // Guardar en la base de datos
    const resume = new Resume({
      originalImage: `/uploads/images/${req.file.filename}`,
      extractedText,
      fileName: req.file.originalname,
      pdfUrl: `/uploads/pdfs/${pdfFilename}`,
      docxUrl: `/uploads/docx/${docxFilename}`
    });

    await resume.save();

    res.status(200).json({
      message: 'Procesamiento exitoso',
      resume: {
        id: resume._id,
        extractedText,
        pdfUrl: resume.pdfUrl,
        docxUrl: resume.docxUrl
      }
    });
  } catch (error) {
    console.error('Error al procesar la imagen:', error);
    res.status(500).json({ message: 'Error al procesar la imagen', error: error.message });
  }
});

// Endpoint para obtener todos los CV
router.get('/api/resumes', async (req, res) => {
  try {
    const resumes = await Resume.find().sort({ createdAt: -1 });
    res.json({ resumes });
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener los CVs', error: error.message });
  }
});

// Endpoint para obtener un CV específico
router.get('/api/resumes/:id', async (req, res) => {
  try {
    const resume = await Resume.findById(req.id);
    if (!resume) {
      return res.status(404).json({ message: 'CV no encontrado' });
    }
    res.json({ resume });
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener el CV', error: error.message });
  }
});

// Endpoint para descargar PDF
router.get('/api/resumes/:id/pdf', async (req, res) => {
  try {
    const resume = await Resume.findById(req.params.id);
    if (!resume) {
      return res.status(404).json({ message: 'CV no encontrado' });
    }
    const pdfPath = path.join(__dirname, '../..', resume.pdfUrl);
    res.download(pdfPath);
  } catch (error) {
    res.status(500).json({ message: 'Error al descargar el PDF', error: error.message });
  }
});

// Endpoint para descargar DOCX
router.get('/api/resumes/:id/docx', async (req, res) => {
  try {
    const resume = await Resume.findById(req.params.id);
    if (!resume) {
      return res.status(404).json({ message: 'CV no encontrado' });
    }
    const docxPath = path.join(__dirname, '../..', resume.docxUrl);
    res.download(docxPath);
  } catch (error) {
    res.status(500).json({ message: 'Error al descargar el DOCX', error: error.message });
  }
});
module.exports = router;