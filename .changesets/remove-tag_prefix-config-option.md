---
bump: "patch"
---

Remove tag_prefix config option. It is no longer necessary for Node.js packages. We already read the package name from the `package.json` file, where the package name includes the prefix already.
