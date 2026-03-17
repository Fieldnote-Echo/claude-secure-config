# Security Rules

## Input Validation

- Validate ALL untrusted input (request params, headers, file uploads, webhook payloads) at the system boundary
- Validate type, length, range, and format — reject unexpected input rather than trying to clean it
- Use schema validation (Zod, Pydantic, JSON Schema) on all external data — not just request bodies, but also WebSocket messages, SSE payloads, and third-party API responses
- Never deserialize untrusted data with unsafe loaders. Use safe alternatives: `yaml.safe_load` not `yaml.load`, `json.loads` not `eval`, `JSON.parse` not `new Function`, Java `ObjectMapper` not `ObjectInputStream`
- File uploads: validate MIME type server-side (not just extension), enforce size limits, store outside webroot with generated filenames

## Access Control

- Authentication is not authorization — every endpoint must verify the user is allowed to access THAT SPECIFIC resource
- Default deny: if no rule explicitly grants access, deny it
- Access control checks happen server-side — never rely on client-side hiding or routing
- For endpoints taking a resource ID: verify the requesting user owns or has permission to that resource (IDOR prevention)
- Security-critical paths (auth, payments, PII) require tests before merge
- Generated code for services should use minimal privileges — non-root users in containers, scoped tokens over admin tokens, restrictive file permissions

## Injection Prevention

- Use parameterized queries or prepared statements for all database access — never concatenate user input into SQL, NoSQL, ORM, or LDAP queries
- Use allowlists and argument arrays for system commands — never pass user input to `exec`, `spawn`, `system`, or `eval`
- Never use `eval()`, `Function()`, `new Function()`, or equivalent dynamic code execution with any data derived from user input. Use lookup tables, switch statements, or schema-validated config objects instead.
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

- Never commit secrets or use them as fallback values. Use your platform's secret manager.
- Never hardcode JWT secrets, API keys, or tokens as fallback values. Instead of `process.env.SECRET || "default-secret"`, fail explicitly: `process.env.SECRET ?? throw new Error("SECRET not set")`

## Error Handling

- Return generic error messages to clients — never expose stack traces, internal paths, or error details
- Log full errors server-side, return sanitized messages to users
- Schema validation errors may return field-level issues (no secrets in schemas)
- For streaming responses: send generic error events, never raw error messages

## CORS

- Use specific origins in CORS configuration — never `*` if endpoints send credentials
- Include `Vary: Origin` header when CORS origin is dynamic

## Supply Chain

- Verify AI-suggested packages exist in the registry before installing — 19.7% are fabricated (slopsquatting)
- Verify the package has meaningful download counts, a real maintainer, and that API methods actually exist in the current version's docs
- Flag GPL, AGPL, SSPL, and EUPL dependencies for review before adding — AI suggests copyleft-licensed packages without flagging license obligations
- Commit lockfiles. CI must use frozen-lockfile installs (`npm ci`, `pip install --require-hashes`). Run `npm audit` / `pip audit` before merging dependency changes. Review lockfile diffs.
- Pin CI actions to full-length commit SHAs. Do not install third-party MCP servers, AI skills, or agent plugins without code review.

## Cryptographic Operations

- Use platform-provided secure random generators (`crypto.randomUUID()`, `secrets.token_hex()`)
- Never use `Math.random()` or equivalent for tokens, IDs, or secrets
- Use standard crypto libraries — never hand-roll cryptography

## MCP and Tool Security

- MCP tool responses are untrusted input — validate and sanitize before rendering, storing, or passing to LLM context
- Maintain an explicit allowlist of permitted tool names — reject calls to unlisted tools
- Never pass raw tool output into `role: "assistant"` messages — use `role: "user"` with structural delimiters
- MCP session IDs and tool authentication tokens are credentials — never log them
- Validate MCP server TLS certificates — require HTTPS in production
- LLM output that triggers side effects (tool invocation, data persistence, external API calls) must be validated against expected schemas before execution

## AI Tooling Safety

- Before opening any cloned repository, inspect `.claude/`, `.cursor/`, `.github/copilot/`, and similar AI tool config directories for unexpected shell commands, URL overrides, or environment variable manipulation
- Never trust `ANTHROPIC_BASE_URL` or similar API endpoint overrides from repository-level config files — these can exfiltrate API keys (CVE-2025-59536, CVE-2026-21852)
- Never run Claude Code with `--dangerously-skip-permissions` on untrusted code — this bypasses all permission checks, deny rules, and hooks
- When reviewing PRs, check for additions to AI tool config directories — these are attack surfaces

## Security Headers

- Set on all responses: `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `X-Frame-Options` or CSP `frame-ancestors`
- Session cookies: `HttpOnly`, `Secure`, `SameSite=Lax` minimum
- Include CSRF tokens on all state-changing requests, or use `SameSite=Strict` cookies
- Never ship debug mode, verbose errors, or development configs to production. Use environment-based gating (`if (env === 'development')`) and strip debug code at build time.

## Logging

- Log auth failures (with IP), rate limit hits, and input validation failures
- Never log tokens, API keys, passwords, or session secrets — even at debug level. Log a masked prefix and length instead: `sk-...****(47 chars)`
- Never log full request bodies that may contain PII. Log request metadata (method, path, status, duration) and field names without values.
