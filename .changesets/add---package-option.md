---
bump: "minor"
---

Add --package option to commands. This allows users to select which packages to
run a command on. To either build, test, publish or run a custom command on.

```
mono build --package package_one
mono test --package package_two
mono publish --package package_one,package_two
mono run --package package_one,package_two
```
