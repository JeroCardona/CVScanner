// backend/src/models/Resume.js
const { Schema, model } = require('mongoose');

const resumeSchema = new Schema({
  originalImage: {
    type: String,
    required: true
  },
  extractedText: {
    type: String,
    required: true
  },
  fileName: String,
  analysis: {
    overallScore: Number,
    missingSections: [String],
    unclearInformation: [{
      section: String,
      issue: String
    }],
    skillSuggestions: [String],
    improvementSuggestions: [String],
    strengths: [String],
    analyzedAt: {
      type: Date,
      default: Date.now
    }
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = model('Resume', resumeSchema);