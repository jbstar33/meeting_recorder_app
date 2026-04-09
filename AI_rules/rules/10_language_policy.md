# Language Policy Rule

## Intent

Keep external communication consistent while preserving English-only control files.

## Rules

1. All user-facing outputs must be written in Korean by default.
2. Rules, skills, agent settings, templates, and internal operating documents must be written in English.
3. If the user explicitly requests a different output language for a specific task, follow that request only for the user-facing response, not for the control files.
4. Preserve code, file paths, API names, identifiers, and command lines in their original language.
5. If an external source is quoted or summarized, explain it to the user in Korean.
6. Sub-agent handoff packets should remain in English unless the receiving runtime requires another language.
7. Logs should preserve the original text of prompts and outputs exactly as sent.
