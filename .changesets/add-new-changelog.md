---
bump: "patch"
---

Add `CHANGELOG.md` file when it did not exist before during publish. When no
`CHANGELOG.md` file existed, and had not been checked in, mono would not commit
the file in the publish commit before.
