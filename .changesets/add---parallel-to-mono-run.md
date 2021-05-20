---
bump: "minor"
---

Add --parallel CLI option to mono run to run commands in parallel like `npm run
build:watch` on all packages in a mono repo.
For example: `mono run npm run build:watch --parallel`.
