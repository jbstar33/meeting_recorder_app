# AGENTS.md

## Purpose

This file is the human-readable operating guide for AI-assisted development in this repository.

It defines:

- how the main AI should behave
- how sub-agents should be used
- what rules are always active
- how language and logging must work

This file is intentionally concise and should be used together with the files under `AI_rules/`.

## Operating Model

Use a manager pattern.

- One main agent is responsible for the end-to-end result.
- Specialized sub-agents may be used for bounded tasks.
- The main agent remains accountable for planning, integration, verification, and the final response.

Default roles:

- Main Orchestrator
- Requirements Agent
- Architecture Agent
- Implementation Agent
- Review Agent

## Always-On Rules

Apply these files as default policy:

- `AI_rules/rules/00_core_behavior.md`
- `AI_rules/rules/10_language_policy.md`
- `AI_rules/rules/20_logging_policy.md`
- `AI_rules/rules/30_orchestration_policy.md`
- `AI_rules/rules/40_sdlc_policy.md`
- `AI_rules/rules/50_quality_gates.md`

## Language Policy

- All user-facing outputs must be written in Korean.
- Rules, skills, templates, and agent settings must remain in English.
- Code, identifiers, commands, and file paths should remain unchanged.

## Logging Policy

Log all meaningful activity.

Minimum required logs:

- user prompts
- agent prompts
- agent outputs
- handoffs
- tool actions
- decisions
- validation results
- final responses

Recommended log location:

- `AI_rules/logs/session-YYYYMMDD-HHMMSS.jsonl`

## SDLC Workflow

Follow this lightweight workflow unless the task is trivial:

1. Discover
2. Define
3. Design
4. Build
5. Verify
6. Document

## Delegation Rules

- Delegate only narrow, well-scoped work.
- Avoid overlapping write scopes across sub-agents.
- Keep critical-path decisions with the main agent.
- Review sub-agent output before using it.
- Log all handoffs and integrations.

## Quality Gates

Before finalizing a response, confirm:

- scope is satisfied
- Korean output requirement is satisfied
- logging requirement is satisfied or explicitly reported unavailable
- risky actions were not taken without approval
- claims are grounded in actual files or validated output
- verification status is stated

## Recommended Files

- Main agent profile: `AI_rules/agents/main_orchestrator.yaml`
- Handoff template: `AI_rules/templates/handoff_template.md`
- Prompt template: `AI_rules/templates/prompt_template.xml`
- Log schema: `AI_rules/templates/session_log.schema.json`

## Practical Instruction

If an AI runtime supports only a single project instruction file:

1. Load this `AGENTS.md`
2. Load the system prompt in `AI_rules/system_prompts/main_orchestrator_system_prompt.md`
3. Treat all files under `AI_rules/rules/` as repository policy

## Repository Intent

This repository is being developed with AI-first collaboration in mind.

That means:

- explicit orchestration is preferred over implicit behavior
- reproducibility is preferred over improvisation
- structured logs are preferred over hidden context
- Korean user communication is mandatory
