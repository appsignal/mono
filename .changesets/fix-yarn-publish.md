---
bump: patch
---

Fix Node.js package publishing using yarn. Calling `yarn publish` prompted the user to enter a new version while Mono already knows what version to upgrade the package to. This prompt is now removed.
