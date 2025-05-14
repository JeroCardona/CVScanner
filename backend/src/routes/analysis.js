const { Router } = require('express');
const router = Router();
const Resume = require('../models/Resume');
const AIAnalysisService = require('../services/aiAnalysis');

// POST /api/analysis/:resumeId - Analyze and structure resume
router.post('/:resumeId', async (req, res) => {
  try {
    const { resumeId } = req.params;    
    const resume = await Resume.findById(resumeId);

    if (!resume) {
      return res.status(404).json({ message: 'Resume not found' });
    }

    if (resume.extractedText.length < 100) {
      return res.status(400).json({ 
        message: 'Resume text is too short for meaningful analysis',
        resumeId: resumeId
      });
    }

    const formattedData = await AIAnalysisService.analyzeResume(resume.extractedText);

    await Resume.findByIdAndUpdate(resumeId, {
      formatted: formattedData,
      analysis: {
        message: 'Análisis completado y formateado correctamente.',
        analyzedAt: new Date()
      }
    });

    res.status(200).json({
      message: 'Resume analyzed and structured successfully',
      resumeId: resumeId,
      formatted: formattedData
    });
  } catch (error) {
    console.error('Error during resume analysis:', error);

    if (error.response) {
      const statusCode = error.response.status;
      const errorData = error.response.data;

      if (statusCode === 429) {
        return res.status(429).json({
          message: 'Rate limit exceeded. Please try again later.',
          error: 'RATE_LIMIT'
        });
      }

      if (statusCode === 401) {
        return res.status(500).json({
          message: 'API authentication error. Please check your API key.',
          error: 'AUTH_ERROR'
        });
      }

      if (statusCode === 400) {
        return res.status(400).json({
          message: 'Bad request to OpenAI API. Check your inputs.',
          error: errorData?.error?.message || 'BAD_REQUEST'
        });
      }
    }

    res.status(500).json({ 
      message: 'Error analyzing resume', 
      error: error.message 
    });
  }
});

// GET /api/analysis/:resumeId - Retrieve analysis
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
        resumeId: resumeId 
      });
    }

    res.status(200).json({
      resumeId: resumeId,
      formatted: resume.formatted
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
