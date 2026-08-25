---
bump: patch
type: fix
---

Refuse to publish when HEAD is detached, and stop before anything is changed. Publishing pushes the current branch to the Git remote, so a detached HEAD has no branch to push. A release started that way used to push the packages to the package manager first and only then fail, which left the packages published with no matching release commit or tag on the Git remote.
