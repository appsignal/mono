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

TODO

### Bootstrap

TODO

### Build

TODO

### Test

TODO

### Changeset

TODO

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

TODO

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
