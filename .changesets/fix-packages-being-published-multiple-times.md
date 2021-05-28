---
bump: "patch"
---

Fix packages being published multiple times. If a package had a changeset and a dependency that was updated, it was recorded twice as being updated causing errors.
