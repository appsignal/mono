# Mono

## 0.2.0

- [2267f21](https://github.com/appsignal/mono//commit/2267f2164b25faf66df2d3a4fdcfbc76c37bb1f0) minor - Add --package option to commands. This allows users to select which packages to
  run a command on. To either build, test, publish or run a custom command on.

  ```
  mono build --package package_one
  mono test --package package_two
  mono publish --package package_one,package_two
  mono run --package package_one,package_two
  ```
- [e427d95](https://github.com/appsignal/mono//commit/e427d956e426274af08c3f2b0ee9a446ca577386) patch - Support different version.rb paths. For the Ruby packages, update the
  `lib/*/version.rb` for the package, instead of using the hardcoded path for the
  AppSignal Ruby gem. This allows us to hopefully release mono with mono later
  on.
- [1020fb7](https://github.com/appsignal/mono//commit/1020fb7d1eb02b021e895891c0b4240257032e58) patch - Improve dir package selection for Node.js. Instead of having a filter by a
  specific directory name, exclude all directories that don't have a
  `package.json` inside them. This way we filter out more directories than just
  `node_modules`.
