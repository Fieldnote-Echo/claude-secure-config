# Code Hygiene

## Pre-Flight Checks

Before writing code, ask:

- **Is the strictest type mode enabled?** If not, enable it. AI has no excuse for weak types.
- **Does every code path handle its failure case?** If any path silently fails, falls through, or swallows an error — fix it.
- **Where does validation happen — at the boundary or deep inside?** If inside, move it to the entry point. Propagate errors upward.
- **Does this already exist in the codebase?** Search before writing. If similar code exists in 2+ places, ask before adding a 3rd.

## Non-Derivable Specifics

Type checker bypasses — never use these to make the compiler shut up:
- `as unknown as`, `@ts-ignore`, `@ts-expect-error`, `# type: ignore` — narrow the type instead (`instanceof`, `in`, discriminant checks) or define a proper type guard

Async pitfalls the model gets wrong:
- Every async path must be awaited, returned to a caller, or explicitly supervised — never fire-and-forget a promise
- Every `fetch`/HTTP request must handle network failure, timeouts, and non-2xx responses
- Use `Promise.allSettled` when partial failure is acceptable, `Promise.all` only when all must succeed

AI-specific failure modes:
- AI code has 1.7x more issues per PR than human code — review before committing
- Remove debugging artifacts (`console.log`, `print()`) before committing

## Eval Anchors

Pattern matching — assert unreachability so the compiler catches unhandled additions:
- TypeScript: `const _: never = value`
- Rust: `unreachable!()`

Error messages — include what was expected, what was received, and where:
- `Expected positive integer for userId, got: ${value}` not `Invalid input`

Verification — run before claiming any task is complete:
- Run typecheck + lint + tests before committing
- If verification commands aren't defined, ask what they are
- Never claim "done" without running the project's test suite
