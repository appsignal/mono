---
bump: patch
type: change
---

Allow ignoring commits that modify changesets. When a commit that modifies a changeset, add the `[skip mono]` tag to not have it be linked in the generated changelog as the relevant change. For example, when updating the changeset to fix a typo after it's been merged, add `[skip mono]` to the "Fix typo" commit to not link to that commit in the changelog.
