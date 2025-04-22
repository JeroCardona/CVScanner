const { Schema, model } = require('mongoose');

const resumeSchema = new Schema({
  user: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
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
