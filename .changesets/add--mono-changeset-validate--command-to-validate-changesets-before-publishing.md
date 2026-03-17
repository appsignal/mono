---
bump: patch
type: add
---

Add `mono changeset validate` command to validate changesets before publishing. Validates `bump`, `type`, and `integrations` metadata. Exits non-zero if any invalid changesets are found.

Pass the `-p` flag to filter to specific packages in monorepos.

Changesets with `integrations` metadata in a project without integrations configured are warnings (not errors) by default, to support copying changesets across repos. Pass `-w`/`--warnings-as-errors` flag to treat warnings as errors.
