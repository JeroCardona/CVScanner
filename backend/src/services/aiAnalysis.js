const axios = require('axios');
const dotenv = require('dotenv');
const path = require('path');
const envPath = path.resolve(__dirname, '../../.env');
dotenv.config({ path: envPath });

class AIAnalysisService {
  constructor() {
    this.apiKey = process.env.OPENAI_API_KEY;
    this.model = process.env.OPENAI_MODEL;
    this.maxTokens = parseInt(process.env.OPENAI_MAX_TOKENS);
  }

  /**
   * Analyzes a resume text using OpenAI's API and returns structured data
   * @param {string} resumeText - The extracted text from the resume
   * @returns {Promise<Object>} - Structured resume information
   */
  async analyzeResume(resumeText) {
    try {
      const response = await axios.post(
        'https://api.openai.com/v1/chat/completions',
        {
          model: this.model,
          messages: [
            {
              role: "system",
              content: `Eres un asistente experto en hojas de vida que debe estructurar la información contenida en un texto extraído por OCR. 
El texto puede tener errores de escritura, lenguaje informal o frases incompletas. 
Debes interpretar el contenido con el mayor sentido posible y devolver un JSON organizado con los siguientes campos:

{
  "fullName": string,
  "profession": string,
  "summary": string,
  "contact": {
    "address": string,
    "email": string,
    "website": string
  },
  "expertise": [string],
  "keyAchievements": [string],
  "experience": [
    {
      "jobTitle": string,
      "company": string,
      "startDate": string,
      "endDate": string,
      "responsibilities": [string]
    }
  ],
  "education": [
    {
      "degree": string,
      "institution": string,
      "startDate": string,
      "endDate": string,
      "details": string
    }
  ],
  "languages": [string],
  "certifications": [string],
  "awards": [string]
}

Si hay campos vacíos o que no se pueden inferir con claridad, deja el valor como string vacío ("") o el arreglo vacío []. 
Sé tolerante con errores de formato y lenguaje.`
            },
            {
              role: "user",
              content: resumeText
            }
          ],
          temperature: 0.2,
          max_tokens: this.maxTokens
        },
        {
          headers: {
            "Authorization": `Bearer ${this.apiKey}`,
            "Content-Type": "application/json"
          }
        }
      );

      const content = response.data.choices[0].message.content;
      const structuredData = JSON.parse(content);
      return structuredData;

    } catch (error) {
      console.error("Error analyzing resume with OpenAI:", error);
      if (error.response) {
        console.error("API response error:", error.response.data);
      }
      throw new Error(`Resume analysis failed: ${error.message}`);
    }
  }
}

module.exports = new AIAnalysisService();
