# AI Rules Apply Guide

## What Has Been Applied

This repository now has a root-level `AGENTS.md`.

That means AI tools that automatically read repository `AGENTS.md` files can discover the project rules from the repository root.

## Effective Entry Point

Primary repository entry file:

- `AGENTS.md`

Primary single-file fallback:

- `AI_rules/system_prompts/combined_project_instruction.md`

## What This Means In Practice

An AI working in this repository should now follow these defaults:

- respond to users in Korean
- keep rules and agent configs in English
- use a main orchestrator pattern
- delegate only bounded tasks
- follow lightweight SDLC stages
- log meaningful prompts and outputs when supported

## Important Limitation

Different AI tools support repository rules differently.

There are two cases:

### Case 1: The tool automatically reads `AGENTS.md`

No extra setup is needed beyond opening this repository.

### Case 2: The tool does not automatically read `AGENTS.md`

Manually provide this file to the tool:

- `AI_rules/system_prompts/combined_project_instruction.md`

## Recommended Setup By Capability

### Single instruction field

Use:

- `AI_rules/system_prompts/combined_project_instruction.md`

### Main agent + sub-agent prompts

Use:

- main agent: `AI_rules/system_prompts/main_orchestrator_system_prompt.md`
- sub-agent prompt: `AI_rules/system_prompts/sub_agent_handoff_system_prompt.md`
- repository policy: `AGENTS.md`

## Verification Checklist

To confirm the rules are active, ask the AI:

1. "From now on, answer me only in Korean."
2. "What is your orchestration pattern in this repository?"
3. "Where should prompts and outputs be logged?"

If the rules are loaded, the AI should answer consistently with the files in this repository.
