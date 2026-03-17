# Code Hygiene

## Type Safety

AI has no excuse for weak types — enforce the strictest mode your language supports:

- **TypeScript:** `strict: true` — never weaken with `any`, use `unknown` and narrow. **Python:** `mypy --strict` or `pyright` strict — annotate all signatures and returns.
- **Rust:** `#![deny(clippy::all, clippy::pedantic)]`. **Go:** `go vet`, `staticcheck` — fix all findings.
- Use the language's type system to make invalid states unrepresentable — prefer discriminated unions over loose string/boolean combos
- Never use `as unknown as`, `@ts-ignore`, `@ts-expect-error`, or `# type: ignore` to bypass the type checker. If the type is wrong, narrow it (`instanceof`, `in`, discriminant checks) or define a proper type guard.

## Error Handling

Catch specific errors, not everything. AI can type out granular exception handling instantly — humans can't, but you can:

- Catch the narrowest exception type that makes sense — `FileNotFoundError` not `OSError`, `SyntaxError` not `Error`
- Never use bare `except:` (Python), `catch (e)` without rethrowing unknowns (TypeScript), or `catch (Exception e)` (Java) at the top level
- Propagate unexpected errors upward — don't swallow them with empty catch blocks or generic fallbacks
- Use `Result`/`Either` types or error returns where the language supports them (`Result<T, E>` in Rust, Go error returns)
- Every catch block must either handle, log+rethrow, or transform the error — never silently ignore

## Async Safety

- Every `await` must have error handling — wrap in try/catch or use `.catch()` on the promise
- Every `fetch`/HTTP request must handle network failure, timeouts, and non-2xx responses
- Handle promise rejections explicitly — attach `.catch()` or use try/catch with await. Never fire-and-forget a promise.
- For concurrent operations: use `Promise.allSettled` when partial failure is acceptable, `Promise.all` only when all must succeed

## Search Before Creating

AI frequently duplicates existing code rather than reusing what's there. Before writing a new function, component, or utility:

- Search the codebase for existing implementations of the same logic
- Reuse and extend existing patterns rather than creating parallel implementations
- If you find similar code in 2+ places, ask whether to refactor before adding a 3rd

## Debt Budget

- Before introducing a workaround or known limitation, search for existing `TODO` and `FIXME` comments in the same file. If there are 3+, resolve one before adding another
- Document known debt in handoff notes between sessions

## AI-Specific Discipline

Things AI should always do that humans skip because they're tedious:

- **Exhaustive pattern matching** — handle every enum variant and union member explicitly. Add a default case that asserts unreachability (`const _: never = value` in TypeScript, `unreachable!()` in Rust) so the compiler catches unhandled additions.
- **Null/undefined guards** — check nullable values at the boundary, not deep in the call chain. Use strict null checks.
- **Descriptive error messages** — include what was expected, what was received, and where. `Expected positive integer for userId, got: ${value}` not `Invalid input`.
- Remove debugging artifacts (`console.log`, `print()`) before committing

## Verification

Run verification before claiming any task is complete:

- Run typecheck + lint + tests before committing
- If verification commands aren't defined, ask what they are
- Never claim "done" without running the project's test suite
- Review AI-generated changes before committing — AI code has 1.7x more issues per PR than human code
