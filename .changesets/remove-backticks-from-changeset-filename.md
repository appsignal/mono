---
bump: "patch"
type: "fix"
---

Fix changeset filenames containing a backticks by replacing it with a dash (`-`). If a backtick was present in the changeset description it would fail to open the right file when prompted.
