// services/aiAnalysis.js
const axios = require('axios');
const dotenv = require('dotenv');
const path = require('path');
const fs = require('fs');

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

class AIAnalysisService {
  constructor() {
    this.apiKey     = process.env.OPENAI_API_KEY;
    this.model      = process.env.OPENAI_MODEL;
    this.maxTokens  = parseInt(process.env.OPENAI_MAX_TOKENS, 10);
    this.outputDir  = path.resolve(__dirname, '../output');
    if (!fs.existsSync(this.outputDir)) {
      fs.mkdirSync(this.outputDir, { recursive: true });
    }
  }

  /**
   * Limpia fences de markdown y deja sólo JSON
   */
  _extractJson(text) {
    let t = text.trim();
    t = t.replace(/^```json\s*/, '').replace(/```$/, '').trim();
    return t;
  }

  /**
   * Llama a OpenAI, parsea el JSON y lo guarda en disco
   * @param {string} resumeText 
   * @returns {Promise<{ data: Object, filePath: string }>}
   */
  async analyzeResume(resumeText) {
    try {
      const resp = await axios.post(
        'https://api.openai.com/v1/chat/completions',
        {
          model: this.model,
          messages: [
            {
              role: "system",
              content: `
Eres un asistente experto en hojas de vida que debe devolver únicamente JSON válido,
sin explicaciones ni markdown. Formato esperado:

{
  "fullName": string,
  "profession": string,
  "summary": string,
  "contact": { "address": string, "email": string, "website": string },
  "expertise": [string],
  "keyAchievements": [string],
  "experience": [{ "jobTitle": string, "company": string, "startDate": string, "endDate": string, "responsibilities": [string] }],
  "education": [{ "degree": string, "institution": string, "startDate": string, "endDate": string, "details": string }],
  "languages": [string],
  "certifications": [string],
  "awards": [string]
}

Si no puede inferir algún campo, déjalo como "" o [].
              `.trim()
            },
            { role: "user", content: resumeText }
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

      // Extraer y parsear JSON
      const raw = resp.data.choices[0].message.content;
      const jsonString = this._extractJson(raw);
      const structured = JSON.parse(jsonString);

      // Guardar en disco
      const filename = `resume_${Date.now()}.json`;
      const filePath = path.join(this.outputDir, filename);
      fs.writeFileSync(filePath, JSON.stringify(structured, null, 2), 'utf8');
      console.log(`✔ JSON guardado en ${filePath}`);

      return { data: structured, filePath };
    } catch (err) {
      console.error("Error en analyzeResume:", err.response?.data || err.message);
      throw err;
    }
  }
}

module.exports = new AIAnalysisService();
