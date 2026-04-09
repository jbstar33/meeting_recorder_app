# Project AGENTS.md

This repository uses the AI operating rules defined under `AI_rules/`.

All AI agents working in this repository must treat the files in `AI_rules/` as the project instruction source of truth.

## Required Instruction Entry Point

If your runtime supports only one repository-level instruction file, use:

- `AI_rules/system_prompts/combined_project_instruction.md`

If your runtime supports multiple instruction sources, load:

1. `AI_rules/AGENTS.md`
2. `AI_rules/system_prompts/main_orchestrator_system_prompt.md`
3. all files under `AI_rules/rules/`

## Mandatory Project Policies

- All user-facing outputs must be written in Korean.
- All rules, skills, templates, and agent settings must remain in English.
- The main AI must act as an orchestrator/manager.
- Sub-agents may be used only for bounded, well-scoped tasks.
- Prompts, outputs, handoffs, decisions, and validations must be logged when the runtime supports logging.

## Default Agent Topology

- Main agent: `AI_rules/agents/main_orchestrator.yaml`
- Requirements agent: `AI_rules/agents/requirements_agent.yaml`
- Architecture agent: `AI_rules/agents/architecture_agent.yaml`
- Implementation agent: `AI_rules/agents/implementation_agent.yaml`
- Review agent: `AI_rules/agents/review_agent.yaml`

## Required Workflow

Use the following lightweight SDLC unless the task is trivial:

1. Discover
2. Define
3. Design
4. Build
5. Verify
6. Document

## Logging

Preferred log directory:

- `AI_rules/logs/`

Preferred schema:

- `AI_rules/templates/session_log.schema.json`

## Human Guidance

If you are a human or an AI operator configuring this repository:

- start with `AI_rules/README.md`
- use `AI_rules/system_prompts/combined_project_instruction.md` for single-file runtimes
- use `AI_rules/system_prompts/main_orchestrator_system_prompt.md` for main-agent system prompts
- use `AI_rules/system_prompts/sub_agent_handoff_system_prompt.md` for sub-agent prompts

## Rule Priority

In case of ambiguity, apply priority in this order:

1. direct user instruction
2. repository safety requirements
3. `AI_rules/system_prompts/combined_project_instruction.md`
4. files under `AI_rules/rules/`
5. agent role files under `AI_rules/agents/`
6. skill files under `AI_rules/skills/`
