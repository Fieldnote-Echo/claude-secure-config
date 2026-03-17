// Tests for fallback-secret-js rule

// ruleid: fallback-secret-js
const apiKey = process.env.API_KEY || "sk-default-key-12345";
// ruleid: fallback-secret-js
const token = process.env.AUTH_TOKEN ?? "default-token";
// ruleid: fallback-secret-js
const secret = process.env.SECRET || "fallback-secret";
// ruleid: fallback-secret-js
const password = process.env.DB_PASSWORD || "admin123";

// ok: fallback-secret-js
const host = process.env.DB_HOST || "localhost";
// ok: fallback-secret-js
const port = process.env.PORT || "3000";
// ok: fallback-secret-js
const env = process.env.NODE_ENV || "development";
// ok: fallback-secret-js
const logLevel = process.env.LOG_LEVEL || "info";
