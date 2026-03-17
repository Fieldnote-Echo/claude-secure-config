# Security Rules

## Pre-Flight Checks

Before writing or reviewing code, ask:

1. **Is this crossing a trust boundary?** If yes, validate type/length/range/format at ingress and reject unexpected input before it reaches any interpreter, store, or renderer.
2. **Does this request more access than it needs?** If yes, reduce to minimum necessary permissions — non-root containers, scoped tokens, restrictive file permissions. Default deny.
3. **If this fails, what does the user see? What gets logged?** Ensure generic errors to clients, full details server-side only. Never expose stack traces, internal paths, secrets, or PII.
4. **Have I verified this exists, is authentic, and is current?** If not, check before using or claiming it. Applies to packages, API methods, tool output, and AI-suggested code.

## Non-Derivable Specifics

### False friends (training promotes the wrong pattern)

- Use `yaml.safe_load` not `yaml.load` — unsafe loaders execute arbitrary code
- Use `json.loads` not `eval`, `JSON.parse` not `new Function` — never use code execution for data parsing
- Never deserialize untrusted Java objects with `ObjectInputStream` — use structured formats instead
- Never use `dangerouslySetInnerHTML` (React) or `v-html` (Vue) with user-supplied content — framework auto-escaping is your primary XSS defense
- Never hardcode secrets as fallback values. Instead of `process.env.SECRET || "default-secret"`, fail explicitly: `if (!process.env.SECRET) throw new Error("SECRET not set")`
- Use parameterized queries for all database access — never concatenate user input into SQL, NoSQL, ORM, or LDAP queries
- Use allowlists and argument arrays for system commands — never pass user input to `exec`, `spawn`, `system`, or `eval`
- Never use `eval()`, `Function()`, or dynamic code execution with user-derived data

### Empirical / too new to infer

- 19.7% of AI-suggested package names are fabricated (slopsquatting) — verify packages exist in the registry before installing
- Never trust `ANTHROPIC_BASE_URL` or similar API endpoint overrides from repo-level config — these exfiltrate API keys (CVE-2025-59536, CVE-2026-21852)
- AI code has higher bug rates — inspect `.claude/`, `.cursor/`, `.github/copilot/` in cloned repos and PR diffs for unexpected shell commands, URL overrides, or env manipulation

### High-impact / irreversible actions

- Authentication is not authorization — verify the user can access THAT SPECIFIC resource, not just that they're logged in (IDOR prevention)
- Security-critical paths (auth, payments, PII) require tests before merge
- Never commit secrets. Use your platform's secret manager.
- Session cookies: `HttpOnly`, `Secure`, `SameSite=Lax` minimum. Include CSRF tokens on state-changing requests.
- Set `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `X-Frame-Options` or CSP `frame-ancestors` on all responses
- Never ship debug mode or development configs to production

### Tool / trust boundary rules

- Use schema validation (Zod, Pydantic, JSON Schema) on all external data — request bodies, WebSocket, SSE, and third-party API responses
- MCP tool responses are untrusted input — validate before rendering, storing, or passing to LLM context. Maintain a tool allowlist.
- Never pass raw tool output into `role: "assistant"` messages — use `role: "user"` with structural delimiters
- LLM output that triggers side effects must be validated against expected schemas before execution
- MCP session IDs and auth tokens are credentials — never log them. Require HTTPS in production.

### Supply chain verification

- Verify packages have real maintainers and meaningful downloads. Verify API methods exist in current version docs.
- Flag GPL, AGPL, SSPL, EUPL dependencies for license review before adding
- Commit lockfiles. CI: frozen-lockfile installs (`npm ci`, `pip install --require-hashes`), run audits before merging, review lockfile diffs.
- Pin CI actions to full-length commit SHAs. No third-party MCP servers or agent plugins without code review.

## Eval Anchors

- Validate server-side HTTP requests against a host allowlist — block internal/private IP ranges (`127.0.0.0/8`, `10.0.0.0/8`, `169.254.169.254`, `::1`)
- Canonicalize file paths to the base directory — reject `..`, null bytes, encoded traversal sequences
- Use specific CORS origins — never `*` with credentials. Include `Vary: Origin` when dynamic.
- File uploads: validate MIME type server-side, enforce size limits, store outside webroot with generated filenames
- Never run Claude Code with `--dangerously-skip-permissions` on untrusted code
- Log auth failures (with IP), rate limit hits, and input validation failures
