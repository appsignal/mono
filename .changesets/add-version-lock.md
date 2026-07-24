---
bump: minor
type: add
---

Add a `version_lock` option that releases every package in a repository together at one shared version. When any package has a change, all packages are released with the same new version number. The release is a single `v<version>` commit and tag, so a repository that already triggers its automation on `v` tags keeps working.

All packages must be at the same version before the release. If they have drifted apart, mono raises an error instead of forcing them into step. Any package that would not otherwise reach the shared version gets a changeset that records why it was released.
