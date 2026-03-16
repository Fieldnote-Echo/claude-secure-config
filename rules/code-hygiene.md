# Code Hygiene

## Type Safety

AI has no excuse for weak types — enforce the strictest mode your language supports:

- **TypeScript:** `strict: true` in tsconfig — never weaken with `any`, use `unknown` and narrow
- **Python:** `mypy --strict` or `pyright` strict mode — annotate all function signatures and returns
- **Rust:** `#![deny(clippy::all, clippy::pedantic)]` — address warnings, don't suppress them
- **Go:** `go vet`, `staticcheck` — fix all findings
- Use the language's type system to make invalid states unrepresentable — prefer discriminated unions over loose string/boolean combos
- Never use `as unknown as`, `@ts-ignore`, `@ts-expect-error`, or `# type: ignore` to bypass the type checker — fix the type instead

## Error Handling

Catch specific errors, not everything. AI can type out granular exception handling instantly — humans can't, but you can:

- Catch the narrowest exception type that makes sense — `FileNotFoundError` not `OSError`, `SyntaxError` not `Error`
- Never use bare `except:` (Python), `catch (e)` without rethrowing unknowns (TypeScript), or `catch (Exception e)` (Java) at the top level
- Propagate unexpected errors upward — don't swallow them with empty catch blocks or generic fallbacks
- Use `Result`/`Either` types or error returns where the language supports them (`Result<T, E>` in Rust, Go error returns)
- Every catch block must either handle, log+rethrow, or transform the error — never silently ignore

## Search Before Creating

AI frequently duplicates existing code rather than reusing what's already there. Before writing a new function, component, or utility:

- Search the codebase for existing implementations of the same logic
- Reuse and extend existing patterns rather than creating parallel implementations
- If you find similar code in 2+ places, ask whether to refactor before adding a 3rd

## Verify Before Using

19.7% of AI-recommended packages are fabricated. Before using any library or API method:

- Verify the package exists in the registry (`npm`, `PyPI`, `crates.io`)
- Verify the specific method/function you're calling exists in the current version's docs
- Check for deprecation notices — AI training data lags behind library releases

## Replacement = Deletion

- When replacing code, delete the old version in the same commit
- No backwards-compatibility shims, renamed `_unused` vars, or `// removed` comments
- If something is unused, delete it completely
- Remove debugging artifacts (`console.log`, `print()`, `TODO`/`FIXME` comments) before committing

## Debt Budget

- Track no more than 3 known-debt items per module
- If adding a 4th, resolve one first or escalate
- Document known debt in handoff notes between sessions

## AI-Specific Discipline

Things AI should always do that humans skip because they're tedious:

- **Exhaustive pattern matching** — handle every enum variant, every union member, every switch case. Add the unreachable/never assertion for default cases.
- **Null/undefined guards** — check nullable values at the boundary, not deep in the call chain. Use strict null checks.
- **Return type annotations** — annotate every function return. Let the compiler verify, don't rely on inference for public APIs.
- **Const correctness** — `const` by default, `readonly` by default, `final` by default. Only make mutable what must be.
- **Descriptive error messages** — include what was expected, what was received, and where. `Expected positive integer for userId, got: ${value}` not `Invalid input`.

## General Discipline

- Review every AI-generated change before committing — AI code has 1.7x more issues per PR than human code
- Do not create abstractions for one-time operations
- Do not add features, refactoring, or "improvements" beyond what was asked
- Three similar lines of code is better than a premature abstraction
- Do not add error handling for scenarios that cannot happen
- Run typecheck + lint + tests before marking any task complete
