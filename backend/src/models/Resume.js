const { Schema, model } = require('mongoose');

const resumeSchema = new Schema({
  user: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: false // CAMBIAR
  },
  ownerDocument: {
    type: String,
    required: true
  },
  originalImage: {
    type: String,
    required: false
  },
  extractedText: {
    type: String,
    required: false
  },
  fileName: String,
  analysis: {
    message: String,
    analyzedAt: {
      type: Date,
      default: Date.now
    }
  },
  formatted: {
    fullName: String,
    profession: String,
    summary: String,
    contact: {
      address: String,
      email: String,
      website: String
    },
    expertise: [String],
    keyAchievements: [String],
    experience: [
      {
        jobTitle: String,
        company: String,
        startDate: String,
        endDate: String,
        responsibilities: [String]
      }
    ],
    education: [
      {
        degree: String,
        institution: String,
        startDate: String,
        endDate: String,
        details: String
      }
    ],
    languages: [String],
    certifications: [String],
    awards: [String]
  },
  // PDF generation fields
  pdfPath: { type: String },
  pdfFilename: { type: String },
  docxPath: { type: String },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = model('Resume', resumeSchema);