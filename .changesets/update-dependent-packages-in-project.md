---
bump: "minor"
---

Update dependent packages in project. When there are multiple packages in the mono repo, and they depend on one another, when a dependency of a package gets updated, it also updates the package that depends on it with the new version number. This only works for Ruby and Node.js currently. It uses a strict version lock system now, but we hope to add support for range based version locks, e.g. `~> 1.2.0`.
