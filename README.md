# Mono

Multi language tool for managing single and mono repository packages.

## Installation

Install mono by downloading the git repository or a [specific
release](https://github.com/appsignal/mono/releases), and then running the
setup script. Mono will add itself to your `$PATH`, which will require a reload
of your shell configuration.

```
cd <path to install mono to>
git clone git@github.com:appsignal/mono.git
cd mono
script/setup
# Reload your shell
source ~/.bashrc
source ~/.zshrc
```

## Usage

After installation the `mono` executable should be available in any directory.

```
mono <command> [options]
```

### Dry run

Note: Dry run is not fully implemented yet. While it won't publish your
packages to a package manager, it will update version files in packages, delete
changeset files and update their changelogs.

Don't want to run the command for real, but want to see what commands it will
perform? Use the dry run feature. Set the `DRY_RUN=true` environment variable
to use dry run mode.

```
DRY_RUN=true mono publish
```

## Configuration

Configuration is done in the `mono.yml` file in the root of the repository you
want to manage. Create a new config file by running `mono init` and customize
it later.

```yaml
# mono.yml example
---
language: nodejs
repo: "https://github.com/appsignal/appsignal-javascript"
npm_client: "yarn"
tag_prefix: "@appsignal/"
packages_dir: "packages"
clean:
  command: "npm run clean"
test:
  command: "npm run test"
```

### Configuration options

- `language`
    - Required.
    - Supported values:
        - `elixir`
        - `nodejs`
        - `ruby`
- `repo`
    - Repository used to link back to from the `CHANGELOG` file.
    - Must be a valid URL.
- `tag_prefix`
    - Git tag prefix used to namespace tags.
    - Example value `@appsignal/` creates the tag `@appsignal/<package>@1.2.3`
- `tag_prefix`
    - Git tag prefix used to namespace tags.
    - Example value `@appsignal/` creates the tag `@appsignal/<package>@1.2.3`
- `packages_dir`
    - Specify the path, from the root of the project, to the directory in which
      the mono project packages can be found. If this config option is
      specified mono will consider this repository a mono repo.
    - Wildcards are not supported.
- `npm_client`
    - Node.js only.
    - Supported values:
        - `npm` - default
        - `yarn`
- `publish`
    - Sub options:
        - `gem_files_dir`
            - Ruby only.
            - Specify which path the `.gem` files to publish can be found if
              not in the root of the project.

### Customize commands

Every preconfigured mono command can be customized by overriding the command
that is run. For the command configuration, add a `command` key and specify
which command to run as the value. This command will be run in _every package_.

```yaml
build:
  command: echo I am run inside the package
```

Commands that can be customized:

- `bootstrap`
- `build`
- `test`
- `clean`
- `publish`

### Hooks

Every command can be customized by adding hooks. These hooks are run _once_
before (`pre`) and after (`post`) the configured command.

```yaml
build:
  pre:  echo I am run _before_ the build command
  post: echo I am run _after_ the build command
```

## Commands

### Init

Add mono to a project. Mono will ask you a couple questions about which
language the project is written in, and where it can find the packages. If a
project is not a mono repo, you can skip the packages step and it will
configure it as a single package project.

Commit the `mono.yml` config file with any other configuration you want to add
to your project.

### Bootstrap

Set up the packages in the project on the host. This command installs the
packages dependencies so the packages are ready for development or testing. For
Node.js projects the packages are also linked on the host, so other projects
on the host can load these local projects in.

```
mono bootstrap
```

#### Options

- `--[no-]ci`
    - When specified the bootstrap command is optimized for Continuous
      Integration (CI) environments.
    - Node.js only.

### Build

Build packages in the project. Every package will be build using the language
specific build process. This step is also run before the [publish](#publish)
command to ensure the latest build will be published.

- Elixir
    - `mix compile`
- Node.js
    - `npm/yarn run build`
    - A `build` script has to be configured in the `package.json` file. If no
      `build` script is configured, the package will be skipped.
- Ruby
    - `gem build`

### Test

Test packages in the project. Every package will be tested using the language
specific test command.

- Elixir
    - `mix test`
- Node.js
    - `npm/yarn run test`
    - A `test` script has to be configured in the `package.json` file. If no
      `test` script is configured, the package will be skipped.
- Ruby
    - `bundle exec rake test`

### Changeset

#### Changeset add

Add a new changeset to a package in the project. Run this command from the root
of the project and it will prompt you with several questions to create a new
changeset file. This command is meant as a convenience, it only writes the file
changeset, which can also be created manually.

```
mono changeset add
```

Prompts:

1. Choose the package for which the changeset applies.
    - When the project is a mono repo, mono will prompt you with a list of
      packages to choose from.
1. Summarize the change:
    - Create a small one line summary of the change. This will be used as the
      changeset filename.
1. Choose the bump level.
    - Choose which bump level the changeset is about. This is one of the bump
      levels specified below. This level affects how mono will determine the
      new version number of the package upon `mono publish`.
1. Lastly mono will ask you if you want to open the changeset file in your
   configured editor. Add more content to the changeset to make the changelog more
   complete for people reading it.

After this commit the changeset file and submit your change.
When `mono publish` is run the changeset file will be removed and its contents
added to the CHANGELOG file.

### Publish

Publish new versions of the package(s) in the project with the publish command.
This command will scan all packages for changeset files and prepare a new
release for those that have them. It will automatically bump the version and
update the changelog of all the packages.

```
mono publish
```

#### Prereleases

If you want to first publish a prerelease, use any of the prerelease option
flags. If the current is already a prerelease of the same type, it will bump
the prerelease version.

```
mono publish --alpha
mono publish --beta
mono publish --rc
```

Examples of releases:

```
1.0.0         + patch changeset           = 1.0.1
1.0.0         + patch changeset + --alpha = 1.0.1-alpha.1
1.0.0-alpha.1 + patch changeset + --alpha = 1.0.1-alpha.2
1.2.3-alpha.1 + minor changeset + --alpha = 1.3.0-alpha.1
1.0.0         + minor changeset + --rc    = 1.1.0-rc.1
```

### Clean

Clean the project to before the [build](#build) step.

```
mono clean
```

- Ruby:
    - Removes `*.gem` files specified in the `gem_files_dir`.
- Elixir:
    - Removes the build artifacts in `_build`.
- Node.js
    - Runs the `clean` script configured for the package's `package.json`.

Clean the project package(s) to a before [build](#build) state.

### Unbootstrap

Resets the project to a state before the initial bootstrap. This command
removes all dependencies and deletes temporary directories.

Run the [clean](#clean) command before this command if you also want to undo
the [build](#build) step.

```
mono unbootstrap
```

- Ruby:
    - Removes the `tmp/` and `vendor/` directories.
- Elixir:
    - Removes the dependencies by calling `mix clean`.
- Node.js
    - Removes the dependencies by removing the `node_modules` directory.

### Run

Run a custom command in every package in the project. By giving `mono run` a
command it will execute it in every package. With the example below it will run
the `do_something` Rake task.

```
mono run rake do_something
```

### Only run commands for specific packages

To only run a mono command for specific packages, select the packages with the
`--package` option. This is supported for the following commands:

- `build`
- `test`
- `clean`
- `publish`
- `run`

```
# Single package
mono <command> --package package_one

# Multiple packages
mono <command> --package package_one,package_two
```

## Publishing

Mono is published using mono. When a new release is ready to be published run
the publish command. Since mono is not published as a Ruby gem, the gem build
and gem push steps are skipped. Mono will only push the new version to the
repository, along with all the other normal publish steps.

```
mono publish
```

## Development

### Installation for development

Mono has no runtime dependencies, but does have some dependencies for
development.

Install the dependencies by running the following command:

```
bundle install
```

### Adding changes

When adding a notable change, create a [changeset file](#changeset) that
describes the change for the `CHANGELOG.md`. Run the command below and enter
the prompts. These changesets will be merged into the `CHANGELOG.md` file upon
[publish](#publishing).

```
mono changeset add
```

Be sure to commit the changeset file in the same commit as the rest of your
changes.

### Testing

This project uses RSpec for the test suite. Run RSpec with the following
command:

```
# Run RSpec test suite
bundle exec rspec

# Run RSpec test suite and generate a test coverage report
COV=1 bundle exec rspec
```

### Linting

This project uses RuboCop to enforce a code style. Run RuboCop with the
following command:

```
bundle exec rubocop
```
