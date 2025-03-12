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
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = model('Resume', resumeSchema);