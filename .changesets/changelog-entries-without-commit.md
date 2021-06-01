---
bump: "patch"
---

Remove commit info from some changeset entries made by mono. Changeset entries made by mono for dependency bumps do not have a commit, as they are part of the "publish" commit, which doesn't exist at time of changelog generation, so omit the information to reduce noise.
