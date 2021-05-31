---
bump: "patch"
---

Support final releases from prereleases without changes. Run `mono publish` for a package with version `1.0.0-rc.4` and mono will publish it as `1.0.0` if no changesets are present. It's always possible to publish another prerelease, as long as there are changesets.
