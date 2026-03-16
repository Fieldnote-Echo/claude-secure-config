# Code Hygiene

## Replacement = Deletion

- When replacing code, delete the old version in the same commit
- No backwards-compatibility shims, renamed `_unused` vars, or `// removed` comments
- If something is unused, delete it completely

## Debt Budget

- Track no more than 3 known-debt items per module
- If adding a 4th, resolve one first or escalate
- Document known debt in handoff notes between sessions

## AI-Specific Discipline

- Review every AI-generated change before committing — AI code has higher bug rates
- Do not create abstractions for one-time operations
- Do not add features, refactoring, or "improvements" beyond what was asked
- Three similar lines of code is better than a premature abstraction
- Do not add error handling for scenarios that cannot happen
