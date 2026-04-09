# Logging Policy Rule

## Intent

Guarantee prompt and output traceability for all meaningful work.

## Rules

1. Save every meaningful prompt and every meaningful output.
2. Log all handoffs between agents.
3. Log important tool actions, validation results, and final decisions.
4. Use append-only JSONL logs unless the runtime requires another format.
5. Never rewrite prior log entries except to add a new correction event.
6. Each log event must include:
   - `timestamp`
   - `session_id`
   - `event_type`
   - `actor`
   - `content`
7. Recommended optional fields:
   - `task_id`
   - `parent_task_id`
   - `agent_name`
   - `input_refs`
   - `output_refs`
   - `language`
   - `status`
   - `risk_level`
8. The main agent must ensure that sub-agent prompts and sub-agent outputs are also logged.
9. If sensitive data is present, log a redacted copy for shared audit trails and keep full-fidelity logs only in secure storage.
10. If logging fails, the agent must warn the user and continue only if the task is still safe to proceed.
