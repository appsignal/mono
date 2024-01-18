---
bump: "patch"
type: "fix"
---

Check if the directory in which Mono is run is Mono project before performing commands. Previously Mono would error with a non-user friendly Ruby error about a missing file. This case is now handled with a better error message.
