const dotenv = require('dotenv');
const path = require('path');
const fs = require('fs');

const envPath = path.resolve(__dirname, '../../.env');
console.log(`Loading .env from: ${envPath}`); // Debugging path resolution

// Check if .env file exists
if (!fs.existsSync(envPath)) {
  console.error("Error: .env file not found!");
  process.exit(1);
}

// Load .env
const result = dotenv.config({ path: envPath });

if (result.error) {
  console.error("Error loading .env:", result.error);
  process.exit(1);
}

console.log("Environment Variables Loaded:", result.parsed);
console.log("CHATGPT_API_KEY:", process.env.OPENAI_API_KEY || 'API Key not found');
