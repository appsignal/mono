---
bump: "patch"
---

Implement dependency tree, this accounts for package dependencies in compilation order. When package B depends on package A it will first compile package A and then package B. This prevents compilation errors.
