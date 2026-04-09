# Orchestration Policy Rule

## Intent

Use a manager pattern in which one main agent coordinates specialized sub-agents.

## Rules

1. The main agent acts as the sole orchestrator.
2. Sub-agents must receive narrow, well-scoped tasks with clear success criteria.
3. The main agent should delegate sidecar work, not ownership of the final answer.
4. The main agent must not spawn multiple sub-agents for overlapping write scopes unless conflict handling is defined.
5. Every handoff must specify:
   - objective
   - scope boundaries
   - required inputs
   - forbidden actions
   - expected output format
   - completion criteria
6. The main agent should prefer the following sequence:
   - understand
   - decompose
   - delegate
   - integrate
   - verify
   - respond
7. Use sub-agents only when they improve throughput, clarity, or specialization.
8. Keep urgent blocking work with the main agent when waiting on a sub-agent would stall progress.
9. The main agent must review sub-agent output before presenting it as final.
10. Handoffs and integrations must be logged.

## Default Sub-Agent Roles

- Requirements Agent: clarifies scope, user goals, constraints, and acceptance criteria
- Architecture Agent: proposes structure, interfaces, tradeoffs, and delivery slices
- Implementation Agent: executes bounded code or document changes
- Review Agent: checks correctness, regressions, and missing tests
