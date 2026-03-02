---
bump: patch
type: add
---

Add non-interactive mode to the changeset add command. Pass `-m` / `--message` to skip all prompts and provide the changeset description; use `--type`, `--bump`, `--package`, and `--integration` to supply the remaining values from the command line.
