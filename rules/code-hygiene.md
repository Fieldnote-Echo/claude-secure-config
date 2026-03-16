# Code Hygiene

## Type Safety

AI has no excuse for weak types — enforce the strictest mode your language supports:

- **TypeScript:** `strict: true` in tsconfig — never weaken with `any`, use `unknown` and narrow
- **Python:** `mypy --strict` or `pyright` strict mode — annotate all function signatures and returns
- **Rust:** `#![deny(clippy::all, clippy::pedantic)]` — address warnings, don't suppress them
- **Go:** `go vet`, `staticcheck` — fix all findings
- Use the language's type system to make invalid states unrepresentable — prefer discriminated unions over loose string/boolean combos
- Never use `as unknown as`, `@ts-ignore`, `@ts-expect-error`, or `# type: ignore` to bypass the type checker. If the type is wrong, narrow it (`instanceof`, `in`, discriminant checks) or define a proper type guard.

## Error Handling

Catch specific errors, not everything. AI can type out granular exception handling instantly — humans can't, but you can:

- Catch the narrowest exception type that makes sense — `FileNotFoundError` not `OSError`, `SyntaxError` not `Error`
- Never use bare `except:` (Python), `catch (e)` without rethrowing unknowns (TypeScript), or `catch (Exception e)` (Java) at the top level
- Propagate unexpected errors upward — don't swallow them with empty catch blocks or generic fallbacks
- Use `Result`/`Either` types or error returns where the language supports them (`Result<T, E>` in Rust, Go error returns)
- Every catch block must either handle, log+rethrow, or transform the error — never silently ignore

## Search Before Creating

AI frequently duplicates existing code rather than reusing what's there. Before writing a new function, component, or utility:

- Search the codebase for existing implementations of the same logic
- Reuse and extend existing patterns rather than creating parallel implementations
- If you find similar code in 2+ places, ask whether to refactor before adding a 3rd

## Verification

Run verification before claiming any task is complete:

- Run typecheck + lint + tests before committing
- If verification commands aren't defined, ask what they are
- Never claim "done" without running the project's test suite
- Review AI-generated changes before committing — AI code has [1.7x more issues](https://www.coderabbit.ai/blog/state-of-ai-vs-human-code-generation-report) per PR than human code

## Replacement = Deletion

- When replacing code, delete the old version in the same commit
- No backwards-compatibility shims, renamed `_unused` vars, or `// removed` comments
- If something is unused, delete it completely
- Remove debugging artifacts (`console.log`, `print()`) before committing

## Debt Budget

- Before introducing a workaround or known limitation, search for existing `TODO` and `FIXME` comments in the same file. If there are 3+, resolve one before adding another
- Document known debt in handoff notes between sessions

## AI-Specific Discipline

Things AI should always do that humans skip because they're tedious:

- **Exhaustive pattern matching** — handle every enum variant and union member explicitly. Add a default case that asserts unreachability (`const _: never = value` in TypeScript, `unreachable!()` in Rust) so the compiler catches unhandled additions.
- **Null/undefined guards** — check nullable values at the boundary, not deep in the call chain. Use strict null checks.
- **Descriptive error messages** — include what was expected, what was received, and where. `Expected positive integer for userId, got: ${value}` not `Invalid input`.
- Do not create abstractions for one-time operations
- Do not add features, refactoring, or "improvements" beyond what was asked
