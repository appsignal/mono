---
bump: "patch"
---

Improve dir package selection for Node.js. Instead of having a filter by a
specific directory name, exclude all directories that don't have a
`package.json` inside them. This way we filter out more directories than just
`node_modules`.
