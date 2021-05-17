---
bump: patch
---

Support different version.rb paths. For the Ruby packages, update the
`lib/*/version.rb` for the package, instead of using the hardcoded path for the
AppSignal Ruby gem. This allows us to hopefully release mono with mono later
on.
