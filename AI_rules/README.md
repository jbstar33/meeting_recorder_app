# AI Rules Pack

## Purpose

This folder defines a reusable multi-agent operating system for AI-assisted vibe coding.

It is designed for a manager-style main agent that orchestrates specialized sub-agents while enforcing:

- Korean-only user-facing outputs
- English-only rules, skills, and agent settings
- persistent prompt/output logging
- explicit handoffs and traceability
- lightweight SDLC guardrails for non-expert users

## Design Principles

This pack follows a few widely used ideas from current agent tooling guidance:

- Use a central manager agent when coordination quality matters more than raw autonomy.
- Split instructions into small, composable rule files instead of one giant prompt.
- Keep prompts explicit, structured, and role-based.
- Log prompts, outputs, handoffs, and tool actions for review.
- Prefer staged delivery: plan, implement, verify, document.

## Folder Layout

```text
AI_rules/
  README.md
  manifest.yaml
  rules/
    00_core_behavior.md
    10_language_policy.md
    20_logging_policy.md
    30_orchestration_policy.md
    40_sdlc_policy.md
    50_quality_gates.md
  skills/
    requirements_analyst.md
    flutter_architect.md
    implementation_worker.md
    qa_reviewer.md
  agents/
    main_orchestrator.yaml
    requirements_agent.yaml
    architecture_agent.yaml
    implementation_agent.yaml
    review_agent.yaml
  system_prompts/
    main_orchestrator_system_prompt.md
    sub_agent_handoff_system_prompt.md
    combined_project_instruction.md
  templates/
    prompt_template.xml
    handoff_template.md
    session_log.schema.json
  logs/
    .gitkeep
```

## Recommended Usage

1. Load `agents/main_orchestrator.yaml` as the main AI profile.
2. Apply all files under `rules/` as always-on instructions.
3. Allow the main agent to assign work using the files under `agents/`.
4. Use the files under `skills/` as reusable role packs.
5. Save every meaningful prompt, response, handoff, and decision into `logs/`.
6. If your runtime supports system prompts, load `system_prompts/main_orchestrator_system_prompt.md`.
7. If your runtime supports only one repository instruction file, use `system_prompts/combined_project_instruction.md`.

## Suggested Operating Model

- Main agent: manager/orchestrator
- Sub-agents: requirements, architecture, implementation, review
- Handoff style: explicit task packet with scope, inputs, constraints, output format
- Approval style: ask the user only for irreversible or high-risk choices

## Logging Standard

Every meaningful interaction should be written as a JSONL event.

Minimum event types:

- `user_prompt`
- `system_prompt`
- `agent_prompt`
- `agent_output`
- `handoff`
- `tool_action`
- `decision`
- `validation`
- `final_response`

Recommended log file pattern:

- `AI_rules/logs/session-YYYYMMDD-HHMMSS.jsonl`

## Why This Structure

This structure is intentionally compatible with how many coding-agent environments think about persistent instructions:

- small scoped rules
- reusable role definitions
- orchestration by manager pattern
- traceability through logs

## Reference Notes

These files were shaped using public guidance patterns from:

- OpenAI Agents SDK guidance on manager-vs-handoff orchestration and tracing
- Anthropic prompting guidance on clear instructions, role prompting, and XML structure
- Cursor guidance on small, composable, version-controlled project rules

Source links:

- [OpenAI Agents SDK: multi-agent orchestration](https://openai.github.io/openai-agents-js/guides/multi-agent/)
- [OpenAI Agents SDK: tracing](https://openai.github.io/openai-agents-python/tracing/)
- [OpenAI practical guide to building AI agents](https://openai.com/business/guides-and-resources/a-practical-guide-to-building-ai-agents/)
- [Anthropic prompt engineering overview](https://docs.anthropic.com/en/docs/prompt-engineering/)
- [Anthropic clear and direct prompting](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/be-clear-and-direct)
- [Anthropic XML tags guidance](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/use-xml-tags)
- [Cursor project rules guidance](https://docs.cursor.com/en/context/rules)
