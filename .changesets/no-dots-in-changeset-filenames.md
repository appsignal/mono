---
bump: "patch"
---

No dots in changeset filenames. Filter out dots in changeset filenames. We
filter out all special symbols that could affect how filetypes are detected and
dots are one of those symbols.
