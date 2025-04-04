// backend/src/routes/analysis.js
const { Router } = require('express');
const router = Router();
const Resume = require('../models/Resume');
const AIAnalysisService = require('../services/aiAnalysis');

// POST /api/analysis/:resumeId - Analyze an existing resume
router.post('/:resumeId', async (req, res) => {
  try {
    const { resumeId } = req.params;    
    // Find the resume in the database
    const resume = await Resume.findById(resumeId);
    if (!resume) {
      return res.status(404).json({ message: 'Resume not found' });
    }
    
    // Check if the resume text is too short for meaningful analysis
    if (resume.extractedText.length < 100) {
      return res.status(400).json({ 
        message: 'Resume text is too short for meaningful analysis',
        resumeId: resumeId
      });
    }
    
    // Send the extracted text to OpenAI for analysis
    let analysisResults;
    analysisResults = await AIAnalysisService.analyzeResume(resume.extractedText);

    
    // Update the resume document with the analysis results
    await Resume.findByIdAndUpdate(resumeId, {
      analysis: {
        ...analysisResults,
        analyzedAt: new Date()
      }
    });
    
    // Return the analysis results
    res.status(200).json({
      message: 'Resume analyzed successfully',
      resumeId: resumeId,
      analysis: analysisResults
    });
  } catch (error) {
    console.error('Error during resume analysis:', error);
    
    // Handle specific OpenAI API errors
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

// GET /api/analysis/:resumeId - Get existing analysis for a resume
router.get('/:resumeId', async (req, res) => {
  try {
    const { resumeId } = req.params;
    
    const resume = await Resume.findById(resumeId);
    if (!resume) {
      return res.status(404).json({ message: 'Resume not found' });
    }
    
    if (!resume.analysis) {
      return res.status(404).json({ 
        message: 'No analysis found for this resume',
        resumeId: resumeId 
      });
    }
    
    res.status(200).json({
      resumeId: resumeId,
      analysis: resume.analysis
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