// routes/analysis.js
const express = require('express');
const router  = express.Router();
const Resume = require('../models/Resume');
const AIAnalysisService = require('../services/aiAnalysis');


// POST /api/analysis/:resumeId - Analiza y estructura el CV
router.post('/:resumeId', async (req, res) => {
  try {
    const { resumeId } = req.params;
    const resume = await Resume.findById(resumeId);
    if (!resume) {
      return res.status(404).json({ message: 'Resume not found' });
    }
    if ((resume.extractedText || '').length < 100) {
      return res.status(400).json({
        message: 'Resume text is too short for meaningful analysis',
        resumeId
      });
    }

    // Desestructuramos data y filePath
    const { data: formattedData, filePath } = 
          await AIAnalysisService.analyzeResume(resume.extractedText);

    // Guardamos en Mongo
    await Resume.findByIdAndUpdate(resumeId, {
      formatted: formattedData,
      analysis: {
        message: 'Análisis completado y formateado correctamente.',
        analyzedAt: new Date(),
        jsonPath: filePath
      }
    });

    res.status(200).json({
      message: 'Resume analyzed and structured successfully',
      resumeId,
      formatted: formattedData,
      jsonFile: filePath
    });
  } catch (error) {
    console.error('Error during resume analysis:', error);

    if (error.response) {
      const { status, data } = error.response;
      if (status === 429) {
        return res.status(429).json({
          message: 'Rate limit exceeded. Please try again later.',
          error: 'RATE_LIMIT'
        });
      }
      if (status === 401) {
        return res.status(500).json({
          message: 'API authentication error. Please check your API key.',
          error: 'AUTH_ERROR'
        });
      }
      if (status === 400) {
        return res.status(400).json({
          message: 'Bad request to OpenAI API. Check your inputs.',
          error: data?.error?.message || 'BAD_REQUEST'
        });
      }
    }

    res.status(500).json({
      message: 'Error analyzing resume',
      error: error.message
    });
  }
});


// GET /api/analysis/:resumeId - Recupera el análisis
router.get('/:resumeId', async (req, res) => {
  try {
    const { resumeId } = req.params;
    const resume = await Resume.findById(resumeId);
    if (!resume) {
      return res.status(404).json({ message: 'Resume not found' });
    }
    if (!resume.formatted) {
      return res.status(404).json({
        message: 'No structured data found for this resume',
        resumeId
      });
    }
    res.status(200).json({
      resumeId,
      formatted: resume.formatted,
      jsonPath: resume.analysis?.jsonPath || null
    });
  } catch (error) {
    console.error('Error retrieving analysis:', error);
    res.status(500).json({
      message: 'Error retrieving analysis',
      error: error.message
    });
  }
});

module.exports = router;
