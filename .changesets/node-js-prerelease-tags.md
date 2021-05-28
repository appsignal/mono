---
bump: "patch"
---

Add support for Node.js prerelease tags. When a prerelease is published, it will automatically tag the release on npmjs.org with the matching prerelease tag. For example: `mono publish --alpha` creates the "alpha" tag.
