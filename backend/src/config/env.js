const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');

const envPath = path.resolve(__dirname, '../../.env');
const result = dotenv.config({ path: envPath });

if (result.error && !fs.existsSync(envPath)) {
  console.warn(`[env] No .env file at ${envPath} — set MONGODB_URI in .env or in PM2 env`);
}
function requireEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(
      `Missing required environment variable: ${name}. ` +
        'Copy backend/.env.example to backend/.env and set it (or export it in your process manager).'
    );
  }
  return value;
}

module.exports = { requireEnv };
