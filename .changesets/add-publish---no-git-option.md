---
bump: "minor"
type: "add"
---

Add mono publish `--no-git` flag. When this flag is given to `mono publish`, the publishing process will not commit the changes to Git, create a tag or push the changes to the remote. This can be useful when you want mono to only generate changelogs and update package version.
