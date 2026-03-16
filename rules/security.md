# Security Rules

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
- Zod/schema validation errors may return field-level issues (no secrets in schemas)
- For streaming responses: send generic error events, never raw error messages

## XSS Prevention

- Never use `dangerouslySetInnerHTML` (React) or `v-html` (Vue) with user-supplied content
- Framework auto-escaping is your primary XSS defense — do not bypass it

## CORS

- Never set CORS origin to `*` if endpoints send credentials
- Use specific origins in CORS configuration
- Include `Vary: Origin` header when CORS origin is dynamic

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
