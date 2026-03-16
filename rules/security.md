# Security Rules

## Input Validation

- Validate ALL untrusted input (request params, headers, file uploads, webhook payloads) at the system boundary
- Validate type, length, range, and format — reject unexpected input rather than trying to clean it
- Never deserialize untrusted data with unsafe loaders (`pickle.loads`, `yaml.load` without SafeLoader, `eval`-based JSON parsing, Java `ObjectInputStream` without type filtering)
- File uploads: validate MIME type server-side (not just extension), enforce size limits, store outside webroot with generated filenames

## Access Control

- Authentication is not authorization — every endpoint must verify the user is allowed to access THAT SPECIFIC resource
- Default deny: if no rule explicitly grants access, deny it
- Access control checks happen server-side — never rely on client-side hiding or routing
- For endpoints taking a resource ID: verify the requesting user owns or has permission to that resource (IDOR prevention)

## Injection Prevention

- Never concatenate user input into SQL, NoSQL, ORM, or LDAP queries — use parameterized queries or prepared statements exclusively
- Never pass user input to command execution functions (`exec`, `spawn`, `system`, `eval`) — use allowlists and argument arrays, not shell strings
- Never use `eval()`, `Function()`, `new Function()`, or equivalent dynamic code execution with any data derived from user input
- Template engines: use auto-escaping by default; manually review any "raw" or "unescaped" output markers

## XSS Prevention

- Never use `dangerouslySetInnerHTML` (React) or `v-html` (Vue) with user-supplied content
- Framework auto-escaping is your primary XSS defense — do not bypass it

## SSRF and Path Traversal

- Never pass user-controlled input to HTTP client functions (`fetch`, `axios`, `requests.get`) without validating against an allowlist of permitted hosts/schemes
- Block requests to internal/private IP ranges (`127.0.0.0/8`, `10.0.0.0/8`, `169.254.169.254`, `::1`) when making server-side requests from user input
- Never construct file paths from user input without canonicalizing the path and verifying it stays within the intended base directory
- Reject path components containing `..`, null bytes, or encoded traversal sequences

## Secrets

- Never commit `.env`, credentials, API keys, or tokens
- Secrets belong in your deployment platform's secret manager, not in version control
- Config files committed to git contain only non-sensitive values

## Auth

- Security-critical paths (auth, payments, PII) require tests before merge
- Never return raw `error.message` to clients — use generic error strings
- Log full errors server-side, return sanitized messages to users

## Error Handling

- Never expose stack traces, internal paths, or error details in responses
- Schema validation errors may return field-level issues (no secrets in schemas)
- For streaming responses: send generic error events, never raw error messages

## CORS

- Never set CORS origin to `*` if endpoints send credentials
- Use specific origins in CORS configuration
- Include `Vary: Origin` header when CORS origin is dynamic

## Security Headers

- Set on all responses: `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `X-Frame-Options` or CSP `frame-ancestors`
- Session cookies: `HttpOnly`, `Secure`, `SameSite=Lax` minimum
- Include CSRF tokens on all state-changing requests, or use `SameSite=Strict` cookies
- Never ship debug mode, verbose errors, or development configs to production

## Supply Chain

- Run `npm audit` / `pip audit` before merging dependency changes
- Never install packages suggested by AI without verifying they exist in the registry
- Review lockfile diffs — unexpected additions need explanation
- Pin CI actions to full-length commit SHAs

## Cryptographic Operations

- Use platform-provided secure random generators (`crypto.randomUUID()`, `secrets.token_hex()`)
- Never use `Math.random()` or equivalent for tokens, IDs, or secrets
- Use standard crypto libraries — never hand-roll cryptography

## Logging

- Never log tokens, API keys, passwords, or session secrets — even at debug level
- Never log full request bodies that may contain PII
- Do log: auth failures, rate limit hits, input validation failures
