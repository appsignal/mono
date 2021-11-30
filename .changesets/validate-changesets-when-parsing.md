---
bump: "patch"
type: "fix"
---

Validate changesets when parsing. With the addition of changeset types, make sure that the changesets have a version bump and type specified and that they are known values. Otherwise, these changesets would not be picked up by mono.
