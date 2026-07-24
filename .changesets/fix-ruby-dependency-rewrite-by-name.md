---
bump: patch
type: fix
---

Fix the Ruby gemspec dependency rewrite so it updates the correct dependency. On release, mono rewrites an `add_dependency` line to the new version of a package. It used to rewrite the first `add_dependency` line it found, regardless of which dependency changed. A gemspec with several literal `add_dependency` lines could have the wrong line rewritten. mono now matches the line by the dependency name.
