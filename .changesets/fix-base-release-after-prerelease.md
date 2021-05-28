---
bump: "patch"
---

Fix base release after prerelease. The `mono publish` command would fail if the package version was a prerelease, updating to a base/final release.
