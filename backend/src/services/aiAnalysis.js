// backend/src/services/aiAnalysis.js
const axios = require('axios');
const dotenv = require('dotenv');
const path = require('path');
const envPath = path.resolve(__dirname, '../../.env');
const env = dotenv.config({ path: envPath });

class AIAnalysisService {
  constructor() {
    this.apiKey = process.env.OPENAI_API_KEY;
    this.model = process.env.OPENAI_MODEL;
    this.maxTokens = parseInt(process.env.OPENAI_MAX_TOKENS);
  }

  /**
   * Analyzes a resume text using OpenAI's API and returns suggestions for improvement
   * @param {string} resumeText - The extracted text from the resume
   * @returns {Promise<Object>} - Analysis results with suggestions
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
              content: `You are a professional resume analyst. Analyze the provided resume and give constructive feedback. 
              Focus on these key areas:
              1. Missing sections or information
              2. Clarity of experience descriptions
              3. Skill representation
              4. Overall structure and organization
              5. Action verbs and quantifiable achievements
              6. Formatting suggestions
              
              Format your response ONLY as a JSON object with the following structure:
              {
                "overallScore": 0-10,
                "missingSections": ["section1", "section2"],
                "unclearInformation": [{"section": "name", "issue": "description"}],
                "skillSuggestions": ["skill1", "skill2"],
                "improvementSuggestions": ["suggestion1", "suggestion2"],
                "strengths": ["strength1", "strength2"]
              }`
            },
            {
              role: "user",
              content: resumeText
            }
          ],
          temperature: 0.2,
          max_tokens: this.maxTokens,
          response_format: { type: "json_object" }
        },
        {
          headers: {
            "Authorization": `Bearer ${this.apiKey}`,
            "Content-Type": "application/json"
          }
        }
      );

      // Extract the content from OpenAI's response
      const content = response.data.choices[0].message.content;
      
      // Parse the JSON
      const analysisResult = JSON.parse(content);

      return analysisResult;
    } catch (error) {
      console.error("Error analyzing resume with OpenAI:", error);
      if (error.response) {
        console.error("API response error:", error.response.data);
      }
      throw new Error(`Resume analysis failed: ${error.message}`);
    }
  }

//   async analyzeResumeWithFunctions(resumeText) {
//     try {
//       const response = await axios.post(
//         'https://api.openai.com/v1/chat/completions',
//         {
//           model: this.model,
//           messages: [
//             {
//               role: "system",
//               content: `You are a professional resume analyst. Analyze the provided resume and give constructive feedback.`
//             },
//             {
//               role: "user",
//               content: resumeText
//             }
//           ],
//           temperature: 0.2,
//           functions: [
//             {
//               name: "analyzeResume",
//               description: "Analyze a resume and provide structured feedback",
//               parameters: {
//                 type: "object",
//                 properties: {
//                   overallScore: {
//                     type: "number",
//                     description: "Overall score of the resume on a scale of 0-10"
//                   },
//                   missingSections: {
//                     type: "array",
//                     items: { type: "string" },
//                     description: "Sections that are missing from the resume"
//                   },
//                   unclearInformation: {
//                     type: "array",
//                     items: {
//                       type: "object",
//                       properties: {
//                         section: { type: "string", description: "Section with unclear information" },
//                         issue: { type: "string", description: "Description of the issue" }
//                       },
//                       required: ["section", "issue"]
//                     },
//                     description: "Areas where information is unclear or could be improved"
//                   },
//                   skillSuggestions: {
//                     type: "array",
//                     items: { type: "string" },
//                     description: "Suggested skills to add or emphasize"
//                   },
//                   improvementSuggestions: {
//                     type: "array",
//                     items: { type: "string" },
//                     description: "General suggestions for improving the resume"
//                   },
//                   strengths: {
//                     type: "array",
//                     items: { type: "string" },
//                     description: "Strengths of the resume"
//                   }
//                 },
//                 required: ["overallScore", "missingSections", "unclearInformation", "skillSuggestions", "improvementSuggestions", "strengths"]
//               }
//             }
//           ],
//           function_call: { name: "analyzeResume" }
//         },
//         {
//           headers: {
//             "Authorization": `Bearer ${this.apiKey}`,
//             "Content-Type": "application/json"
//           }
//         }
//       );

//       // Extract the function call arguments from OpenAI's response
//       const functionCallArguments = response.data.choices[0].message.function_call.arguments;
      
//       // Parse the JSON
//       const analysisResult = JSON.parse(functionCallArguments);

//       return analysisResult;
//     } catch (error) {
//       console.error("Error analyzing resume with OpenAI function calling:", error);
//       if (error.response) {
//         console.error("API response error:", error.response.data);
//       }
//       throw new Error(`Resume analysis failed: ${error.message}`);
//     }
//   }
}

module.exports = new AIAnalysisService();