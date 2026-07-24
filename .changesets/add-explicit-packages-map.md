---
bump: minor
type: add
---

Add support for listing a repository's packages explicitly with a `packages` map in `mono.yml`, instead of globbing a directory with `packages_dir`. The map pairs each package name with its path, and one of those paths may be `.` to root a package at the repository root. This lets a repository publish more than one package without moving everything into a `packages_dir` layout. The `packages` and `packages_dir` options are mutually exclusive.

For Node.js projects, a package rooted at the repository root runs its own scripts at the root, because it is not a workspace member and cannot be selected with the npm or yarn workspace flag. Nested packages keep using the workspace selector as before.
