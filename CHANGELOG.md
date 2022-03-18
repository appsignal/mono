# Mono

## 0.6.2

### Added

- [bdbbcf5](https://github.com/appsignal/mono//commit/bdbbcf5463e496ebb2537842af8a14ac1ada16cd) patch - Support Node.js package.json `devDependencies`. Any package in the workspace that's specified as a dev dependency by other packages are also updated upon publish.

### Fixed

- [546b81a](https://github.com/appsignal/mono//commit/546b81af8b5facf8a044d73b712e43566c9e66e6) patch - Strip out colons from changeset filenames. The colon and semicolon symbols are now replaced with a dash symbol.

## 0.6.1

### Fixed

- [393d60d](https://github.com/appsignal/mono//commit/393d60de44fce6ad54c3c652f8e58fa9c333cdf3) patch - Fix publishing with changeset filenames containing unescaped symbols.
- [3eb2f57](https://github.com/appsignal/mono//commit/3eb2f5726a82732cc21f3cdce83b3fc621c02a31) patch - Prevent duplicate dependency bump changesets. Previously, if a package's dependency had a dependency that was also updated, the final package in the tree would track multiple changesets for the same dependency update.

## 0.6.0

### Added

- [d81182b](https://github.com/appsignal/mono//commit/d81182b0921e09d0b02a514b11000c1cce5b24e3) minor - Add types to changesets. The following types are supported: add, change, deprecate, remove, fix and security. Use the appropriate one for the change and the changelog will include sections for every present type of change. This will make it easier for readers to understand the impact of a new release's changes.
- [dd19f67](https://github.com/appsignal/mono//commit/dd19f67c7cedc2d472e3950fe59860473d625d8a) minor - Add support for the `fish` shell in the `script/setup` installation script.
- [dd19f67](https://github.com/appsignal/mono//commit/dd19f67c7cedc2d472e3950fe59860473d625d8a) patch - Print changeset summaries on publish. This makes it easier to tell which changes are about to be published for every package.
- [dd19f67](https://github.com/appsignal/mono//commit/dd19f67c7cedc2d472e3950fe59860473d625d8a) patch - Print changeset type on publish preview.

### Fixed

- [81b0614](https://github.com/appsignal/mono//commit/81b06140acd7ab8823627b28a8cb6d18546d7cd1) patch - Validate changesets when parsing. With the addition of changeset types, make sure that the changesets have a version bump and type specified and that they are known values. Otherwise, these changesets would not be picked up by mono.
- [dd19f67](https://github.com/appsignal/mono//commit/dd19f67c7cedc2d472e3950fe59860473d625d8a) patch - Validate user input of the package number for changesets in mono repositories better. Non number characters and other invalid strings will prompt the user again to enter a valid package number.

## 0.5.9

- [616571e](https://github.com/appsignal/mono//commit/616571e8aebb77ab2aa9240ae803e0636aeb9bf1) patch - Add `mono-dev` executable to allow for testing mono. The `mono` executable will not allow usage of mono with uncommitted changes. This will prevent accidental usage of mono with uncommitted changes that would cause mono to crash unexpectedly.
- [43cc5fc](https://github.com/appsignal/mono//commit/43cc5fc133afd6faccecc1e6c966a5c0bb0bd279) patch - Retry failed publish commands. When a publish command like `gem push` fails, prompt the user to retry it rather than fail the entire publish process.
- [709caa4](https://github.com/appsignal/mono//commit/709caa41acba2a1e2f352db885570680b48f46ae) patch - Fix mono production check directory. It would perform the check in the current directory, not the mono install directory.
- [f70a877](https://github.com/appsignal/mono//commit/f70a877adb7f36e30a63acf104bb119da4e8d588) patch - Check Git branch for mono to prevent accidental usage of mono on an unmerged branch.
- [e89e57c](https://github.com/appsignal/mono//commit/e89e57c88f7df7281531da6fdb37010e67fa7461) patch - Skip Git check if Git command fails. If `git status` fails in the `mono` directory, skip the check. It's probably a production download.

## 0.5.8

- [244ec4f](https://github.com/appsignal/mono//commit/244ec4f633754c9f1f85578fbc1fb00ce0843401) patch - Aside from working on Elixir projects with their version set in a module attribute (`@version "1.2.3"` and `version: @version`), add support for projects with their versions set directly in the `project` block (`version: "1.2.3"`).
- [221dd5f](https://github.com/appsignal/mono//commit/221dd5f705b4aaec462b6fa500f3669b2def3c60) patch - Move the [ci-ckip] tag to commit message body instead of printing it in the subject.
- [940b0ac](https://github.com/appsignal/mono//commit/940b0acac4580bada23ba2989f1413ce0e425db5) patch - Fix Node.js package publishing using yarn. Calling `yarn publish` prompted the user to enter a new version while Mono already knows what version to upgrade the package to. This prompt is now removed.

## 0.5.7

- [3f06eec](https://github.com/appsignal/mono//commit/3f06eec9f4d43ad0dd4d177010cafd435acac00e) patch - Improve circular dependency error message.
- [ac15342](https://github.com/appsignal/mono//commit/ac1534236933864ae412487c88eb674201d27593) patch - Print exit message with line break. This gives a more user friendly end stopping the publish process, rather than a message with a missing line break.
- [54540cb](https://github.com/appsignal/mono//commit/54540cbcf195327390c775c38b15a1486c0a116b) patch - Improve command failure error message. Explain in more detail what the message is about.
- [8a86a6e](https://github.com/appsignal/mono//commit/8a86a6edb4ea40515e3047d955fdbdc20d3a6591) patch - Require npm 7.12 at minimum, this should fix the issue with certain workspaces not being found on older npm versions.

## 0.5.6

- [dd2a62f](https://github.com/appsignal/mono//commit/dd2a62f347fa40aa705912aec198e83f50dec96f) patch - Remove commit info from some changeset entries made by mono. Changeset entries made by mono for dependency bumps do not have a commit, as they are part of the "publish" commit, which doesn't exist at time of changelog generation, so omit the information to reduce noise.
- [2c54ba1](https://github.com/appsignal/mono//commit/2c54ba199bdd48201b4a1d1dd78a46005ba8983f) patch - Implement dependency tree, this accounts for package dependencies in compilation order. When package B depends on package A it will first compile package A and then package B. This prevents compilation errors.

## 0.5.5

- [0a3f464](https://github.com/appsignal/mono//commit/0a3f464b63129d1eb0acf049a3f66cd31519b3de) patch - Support final releases from prereleases without changes. Run `mono publish` for a package with version `1.0.0-rc.4` and mono will publish it as `1.0.0` if no changesets are present. It's always possible to publish another prerelease, as long as there are changesets.

## 0.5.4

- [ec52f98](https://github.com/appsignal/mono//commit/ec52f9836a7db7a122f193a7fc2cea60272e2614) patch - Fix prerelease version incrementation. Mono would not properly update an alpha 1 release to an alpha 2 release.

## 0.5.3

- [bcd4b76](https://github.com/appsignal/mono//commit/bcd4b76c74c43c5751c833d3f9528dbc6d5e5f1b) patch - Fix packages being published multiple times. If a package had a changeset and a dependency that was updated, it was recorded twice as being updated causing errors.
- [c0dce23](https://github.com/appsignal/mono//commit/c0dce236b2701b148b2a2f1487421700ad9a6991) patch - Fix dependent package versions to prereleases. Dependencies wouldn't be updated to use a prerelease version if a prerelease version was chosen on `mono publish --alpha|beta|rc`.

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
