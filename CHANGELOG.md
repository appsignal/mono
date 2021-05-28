# Mono

## 0.5.2

- [5bb53cc](https://github.com/appsignal/mono//commit/5bb53cc7f08865e8adb18e5f944a1498620cdb24) patch - Remove tag_prefix config option. It is no longer necessary for Node.js packages. We already read the package name from the `package.json` file, where the package name includes the prefix already.

## 0.5.1

- [f289e39](https://github.com/appsignal/mono//commit/f289e398bee433a53771bb6808440e48ab734353) patch - Run npm publish in package dir to publish packages. Fixes the inability to publish packages with npm.

## 0.5.0

- [5de62a5](https://github.com/appsignal/mono//commit/5de62a56cc0272c11f10887569d6c5c0ee52d682) patch - Add support for Node.js prerelease tags. When a prerelease is published, it will automatically tag the release on npmjs.org with the matching prerelease tag. For example: `mono publish --alpha` creates the "alpha" tag.
- [4bfd850](https://github.com/appsignal/mono//commit/4bfd850ab933b42b9cc65c80c6111220230f08aa) patch - Fix base release after prerelease. The `mono publish` command would fail if the package version was a prerelease, updating to a base/final release.

## 0.5.0.alpha.1

- [9ddd720](https://github.com/appsignal/mono//commit/9ddd720090f9baaeef2aab7322d1b377c5131c34) minor - Update dependent packages in project. When there are multiple packages in the mono repo, and they depend on one another, when a dependency of a package gets updated, it also updates the package that depends on it with the new version number. This only works for Ruby and Node.js currently. It uses a strict version lock system now, but we hope to add support for range based version locks, e.g. `~> 1.2.0`.
- [80979ab](https://github.com/appsignal/mono//commit/80979ab92a130204a5ed883c6f288ce9cb06628e) patch - Remove all node_modules on unbootstrap. Also remove the node_modules directory
  for mono repos in the packages dir.

## 0.4.0

- [6070517](https://github.com/appsignal/mono//commit/6070517bbb819857a44aae13ab0a054dcbaa34ce) minor - Add the unbootstrap command. This command will be the same behavior as the
  previous "clean" command. The clean command will instead be the opposite of the
  "build" command, cleaning up after the build command, removing any build
  artifacts.

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
