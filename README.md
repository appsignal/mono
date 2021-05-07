# Mono

Multi language tool for managing single and mono repository packages.

## Installation

```
bin/setup
```

## Usage

After installation the `mono` executable should be available in any directory.

```
mono <command> [options]
```

### Dry run

Note: Dry run is not fully implemented yet. While it won't publish your packages to a package manager, it will update version files in packages, delete changeset files and update their changelogs.

Don't want to run the command for real, but want to see what commands it will perform? Use the dry run feature. Set the `DRY_RUN=true` environment variable to use dry run mode.

```
DRY_RUN=true mono publish
```

## Configuration

Create a `mono.yml` file in the root of the repository you want to manage.

```
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
    - Specify the directory in which the mono repo's packages can be found. If specified mono will consider this repository a mono repo.
    - Wildcards are not supported.
- `npm_client`
    - Node.js only.
    - Supported values:
        - `npm` - default
        - `yarn`
- `publish`
    - Sub options:
        - `gem_files`
            - Ruby only.
            - Specify where the `.gem` files to publish can be found.
            - Currently required for `ruby` packages, shouldn't be in the future, but default to `.gem` in the root of the repository.

## Commands

### Init

Add mono to a project. Mono will ask you a couple questions about which
language the project is written in, and where it can find the packages. If a
project is not a mono repo, you can skip the packages step and it will
configure it as a single package project.

Commit the `mono.yml` config file with any other configuration you want to add.

### Bootstrap

TODO

### Build

TODO

### Test

TODO

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
1.0.0         + minor changeset + --rc    = 1.1.0-rc.1
```

### Clean

TODO

### Run

Run a custom command in every package in the project. By giving `mono run` a
command it will execute it in every package. With the example below it will run
the `do_something` Rake task.

```
mono run rake do_something
```

## Development

### Testing

```
# Install dependencies
bundle install
# Run RSpec test suite
bundle exec rspec
# Run RSpec test suite and generate a test coverage report
COV=1 bundle exec rspec
```
