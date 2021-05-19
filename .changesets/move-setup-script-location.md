---
bump: "patch"
---

Move setup script location to `script/setup`. Prevents the mono `setup` script
becoming available everywhere, like the `mono` executable. Which could
accidentally run the mono setup script outside of the mono project directory.
