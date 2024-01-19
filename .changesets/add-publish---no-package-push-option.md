---
bump: "minor"
type: "add"
---

Add mono publish `--no-package-push` flag. When this flag is given to `mono publish`, the publishing process will not push the packages to their version managers. This can be useful when you want mono to only generate changelogs and update package version.
