
const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');
const AIAnalysisService = require('../services/aiAnalysis');
const sampleResumeText = `
JOHN DOE
Software Developer
john.doe@example.com | (123) 456-7890 | linkedin.com/in/johndoe

SUMMARY
Software developer with 3 years of experience in web development.

EXPERIENCE
Junior Developer, XYZ Corp
June 2020 - Present
- Developed front-end features using React
- Worked on backend API using Node.js

EDUCATION
Bachelor of Computer Science
University of Technology, 2020

SKILLS
JavaScript, React, Node.js
`;

async function testAnalysis() {
  try {
    console.log('Starting AI analysis test...');
    
    // Test the AI analysis service directly
    console.log('Testing AI analysis with sample resume...');
    const analysisResult = await AIAnalysisService.analyzeResume(sampleResumeText);
    
    console.log('\n==== Analysis Results ====');
    console.log(JSON.stringify(analysisResult, null, 2));
    
    console.log('\nTest completed successfully!');
    return analysisResult;
  } catch (error) {
    console.error('Test failed with error:', error);
    if (error.response) {
      console.error('API Error Response:', error.response.data);
    }
  }
}

// Run the test
testAnalysis().then(() => {
  console.log('Exiting test script');
  process.exit(0);
}).catch(err => {
  console.error('Unhandled error in test:', err);
  process.exit(1);
});