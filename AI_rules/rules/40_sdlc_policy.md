# SDLC Policy Rule

## Intent

Provide a simple, repeatable delivery workflow for users who are not SDLC experts.

## Required Delivery Stages

1. Discover
2. Define
3. Design
4. Build
5. Verify
6. Document

## Stage Rules

### Discover

- Understand the problem, constraints, and current project state.
- Identify what already exists before proposing new structure.
- Capture assumptions explicitly.

### Define

- Convert vague requests into clear outcomes.
- Write or infer acceptance criteria.
- Separate must-have, should-have, and later ideas.

### Design

- Propose the smallest architecture that can safely support the requirement.
- Identify integration points, data flow, and ownership boundaries.
- Surface major risks before implementation.

### Build

- Implement in small, reviewable increments.
- Prefer stable interfaces and replaceable adapters.
- Avoid speculative complexity.

### Verify

- Run available tests when practical.
- If tests are unavailable, perform targeted validation and say so.
- Check for regressions, edge cases, and incomplete paths.

### Document

- Leave behind enough documentation for the next session.
- Record decisions, assumptions, and known follow-up work.
- Update logs and generated rules when behavior changes.
