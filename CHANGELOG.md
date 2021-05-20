# Mono

## 0.3.0

- [c4bc910](https://github.com/appsignal/mono//commit/c4bc9103fcf19d60a5989841a3ef224c74008c33) minor - Add --parallel CLI option to mono run to run commands in parallel like `npm run
  build:watch` on all packages in a mono repo.
  For example: `mono run npm run build:watch --parallel`.
- [4e17aa5](https://github.com/appsignal/mono//commit/4e17aa50817e6ae12dff45481cdadcaa27a08516) patch - Add `CHANGELOG.md` file when it did not exist before during publish. When no
  `CHANGELOG.md` file existed, and had not been checked in, mono would not commit
  the file in the publish commit before.
- [5ec9e9d](https://github.com/appsignal/mono//commit/5ec9e9d29f0ac360ad3538d6145cd50262ce4b6d) patch - Fix inconsistencies in clean command from other commands. Add `--package` CLI
  option.
- [47f3505](https://github.com/appsignal/mono//commit/47f3505cdc73a7090233e6f8114715b8ea9914a2) patch - Clean the Node.js root as well. This change also clears the root `node_modules`
  directory for mono repos.
- [4972148](https://github.com/appsignal/mono//commit/497214837c4380f0ebbbcb38e996caf31b9f927a) patch - Validate `--package` names. When specifying a package with the `--package` CLI
  option, mono will exit with an error if no package with the specified name does
  not exist.
- [ce8c835](https://github.com/appsignal/mono//commit/ce8c835ee2b42082682266fd9103f465af5dad8e) patch - No dots in changeset filenames. Filter out dots in changeset filenames. We
  filter out all special symbols that could affect how filetypes are detected and
  dots are one of those symbols.
- [19add5b](https://github.com/appsignal/mono//commit/19add5b75693a058df0b6e8a13aaffcd31f49176) patch - Move setup script location to `script/setup`. Prevents the mono `setup` script
  becoming available everywhere, like the `mono` executable. Which could
  accidentally run the mono setup script outside of the mono project directory.

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
