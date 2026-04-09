# Branching Strategy

This repository uses a simple GitHub flow style branch layout for PR-based work.

## Branch Types

- `main`: stable branch, always deployable
- `feature/<short-name>`: new user-facing functionality
- `fix/<short-name>`: bug fixes and corrections
- `refactor/<short-name>`: internal code restructuring without behavior change
- `chore/<short-name>`: dependency updates, tooling, docs, and housekeeping
- `hotfix/<short-name>`: urgent production fixes

## Naming Rules

- Use lowercase letters and hyphens
- Keep names short and specific
- Prefer one purpose per branch
- Example: `feature/transcript-search`

## PR Flow

1. Create a branch from `main`.
2. Make a single focused change.
3. Open one PR per branch.
4. Merge after review and checks pass.
5. Delete the branch after merge.

## Recommended Mapping For This Project

- `feature/recording-ui`
- `feature/transcript-list`
- `feature/transcript-edit`
- `feature/transcript-search`
- `feature/stt-integration`
- `feature/offline-ai`
- `fix/<issue>`
- `chore/<task>`

## PR Expectations

- One branch should map to one PR
- Keep PRs small when possible
- Include screenshots for UI changes
- Mention test coverage or verification steps
- Call out any storage, permission, or migration impact
