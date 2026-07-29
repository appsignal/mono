---
bump: patch
type: fix
---

Complete the `DRY_RUN=true mono publish` mode so it runs from start to finish without crashing. Before this change, dry-run skipped every command, including the read-only ones. Reading the existing Git tags returned nothing and then raised an error, so the command crashed before it could show its plan.

Dry-run now runs read-only commands, such as reading the existing Git tags, so its control flow matches a real publish. Every command that changes something or talks to a remote is printed with a `[dry-run]` marker and is not run. This includes the Git commit, the Git tag, the Git push and the push to the package manager. As before, version files, changelogs and changeset files are still updated on disk.
