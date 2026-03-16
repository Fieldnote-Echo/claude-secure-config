# Security Rules

## Input Validation

- Validate ALL untrusted input (request params, headers, file uploads, webhook payloads) at the system boundary
- Validate type, length, range, and format — reject unexpected input rather than trying to clean it
- Use schema validation (Zod, Pydantic, JSON Schema) on all external data — not just request bodies, but also WebSocket messages, SSE payloads, and third-party API responses
- Never deserialize untrusted data with unsafe loaders (`pickle.loads`, `yaml.load` without SafeLoader, `eval`-based JSON parsing, Java `ObjectInputStream` without type filtering)
- File uploads: validate MIME type server-side (not just extension), enforce size limits, store outside webroot with generated filenames

## Access Control

- Authentication is not authorization — every endpoint must verify the user is allowed to access THAT SPECIFIC resource
- Default deny: if no rule explicitly grants access, deny it
- Access control checks happen server-side — never rely on client-side hiding or routing
- For endpoints taking a resource ID: verify the requesting user owns or has permission to that resource (IDOR prevention)

## Injection Prevention

- Use parameterized queries or prepared statements for all database access — never concatenate user input into SQL, NoSQL, ORM, or LDAP queries
- Use allowlists and argument arrays for system commands — never pass user input to `exec`, `spawn`, `system`, or `eval`
- Never use `eval()`, `Function()`, `new Function()`, or equivalent dynamic code execution with any data derived from user input
- Template engines: use auto-escaping by default; manually review any "raw" or "unescaped" output markers

## XSS Prevention

- Never use `dangerouslySetInnerHTML` (React) or `v-html` (Vue) with user-supplied content
- Framework auto-escaping is your primary XSS defense — do not bypass it

## SSRF and Path Traversal

- Validate server-side HTTP requests against an allowlist of permitted hosts/schemes — never pass user-controlled input directly to `fetch`, `axios`, or `requests.get`
- Block requests to internal/private IP ranges (`127.0.0.0/8`, `10.0.0.0/8`, `169.254.169.254`, `::1`) when making server-side requests from user input
- Canonicalize file paths and verify they stay within the intended base directory — never construct paths directly from user input
- Reject path components containing `..`, null bytes, or encoded traversal sequences

## Secrets

- Never commit `.env`, credentials, API keys, or tokens — including as fallback/default values in code
- Secrets belong in your deployment platform's secret manager, not in version control
- Config files committed to git contain only non-sensitive values
- Never hardcode JWT secrets, API keys, or tokens as fallback values (e.g., `process.env.SECRET || "default-secret"`)

## Auth

- Security-critical paths (auth, payments, PII) require tests before merge
- Return generic error strings to clients — never raw `error.message`
- Log full errors server-side, return sanitized messages to users

## Error Handling

- Return generic error messages to clients — never expose stack traces, internal paths, or error details
- Schema validation errors may return field-level issues (no secrets in schemas)
- For streaming responses: send generic error events, never raw error messages

## Async Safety

- Every `await` must have error handling — wrap in try/catch or use `.catch()` on the promise
- Every `fetch`/HTTP request must handle network failure, timeouts, and non-2xx responses
- Handle promise rejections — never leave promises unhandled (`node --unhandled-rejections=throw`, or equivalent)
- For concurrent operations: use `Promise.allSettled` when partial failure is acceptable, `Promise.all` only when all must succeed

## CORS

- Use specific origins in CORS configuration — never `*` if endpoints send credentials
- Include `Vary: Origin` header when CORS origin is dynamic

## Security Headers

- Set on all responses: `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `X-Frame-Options` or CSP `frame-ancestors`
- Session cookies: `HttpOnly`, `Secure`, `SameSite=Lax` minimum
- Include CSRF tokens on all state-changing requests, or use `SameSite=Strict` cookies
- Never ship debug mode, verbose errors, or development configs to production

## Supply Chain

- Verify AI-suggested packages exist in the registry before installing — 19.7% of AI-recommended packages are fabricated
- Verify that API methods called on real libraries actually exist in the current version's documentation
- Run `npm audit` / `pip audit` before merging dependency changes
- Review lockfile diffs — unexpected additions need explanation
- Pin CI actions to full-length commit SHAs

## Cryptographic Operations

- Use platform-provided secure random generators (`crypto.randomUUID()`, `secrets.token_hex()`)
- Never use `Math.random()` or equivalent for tokens, IDs, or secrets
- Use standard crypto libraries — never hand-roll cryptography

## Logging

- Log auth failures (with IP), rate limit hits, and input validation failures
- Never log tokens, API keys, passwords, or session secrets — even at debug level
- Never log full request bodies that may contain PII
