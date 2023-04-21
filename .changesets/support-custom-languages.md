---
bump: "minor"
type: "add"
---

Support custom languages with the custom language option. Example custom language configuration:

```yaml
---
language: custom
repo: "https://github.com/appsignal/appsignal-python"
bootstrap:
  command: "echo bootstrap"
clean:
  command: "hatch clean"
build:
  command: "hatch build"
publish:
  command: "hatch publish"
test:
  command: "hatch run test:pytest"
read_version: "hatch version"
write_version: "hatch version"
```
