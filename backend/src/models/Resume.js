const { Schema, model } = require('mongoose');

const resumeSchema = new Schema({
  originalImage: String,
  extractedText: String,
  fileName: String,
  pdfUrl: String,
  docxUrl: String,
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = model('Resume', resumeSchema);