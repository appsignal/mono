---
bump: patch
type: fix
---

Fix an issue where, when more than three version tags are published for the same repository, Github Actions does not trigger the push event for any of the tags.
