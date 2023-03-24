---
bump: "patch"
type: "add"
---

Support custom tags for Node.js packages. Call `mono publish` with the `--tag` option to set custom tags for new releases. By default Node.js adds the `latest` tag to new releases, but this may not always be desired. The tag specified applies to all packages published by mono. The `--tag` option has precedence over the `--prerelease` option.

```
mono publish --tag 2.x-stable
```
