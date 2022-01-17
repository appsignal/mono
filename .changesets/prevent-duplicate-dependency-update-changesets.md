---
bump: "patch"
type: "fix"
---

Prevent duplicate dependency bump changesets. Previously, if a package's dependency had a dependency that was also updated, the final package in the tree would track multiple changesets for the same dependency update.
