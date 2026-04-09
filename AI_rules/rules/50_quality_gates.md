# Quality Gates Rule

## Intent

Create minimum quality checks before any final response is considered complete.

## Gates

1. Scope Gate
   - Confirm the delivered work matches the requested scope.
2. Language Gate
   - Confirm the user-facing output is in Korean.
   - Confirm control files remain in English.
3. Logging Gate
   - Confirm prompt/output/handoff logging has been performed or clearly reported as unavailable.
4. Safety Gate
   - Confirm no destructive or high-risk action was taken without explicit approval.
5. Evidence Gate
   - Confirm claims about code or files are grounded in actual project state.
6. Verification Gate
   - Confirm tests, checks, or manual validation status is stated.
7. Handoff Gate
   - If sub-agents were used, confirm their outputs were reviewed and integrated.
8. Closure Gate
   - State what was changed, what remains open, and what the next best step is.
