# Mono quick start guide

## First time using mono in a project

Are you using mono for the first time in a project that has been converted to
mono since you last used it? Or are you using mono for the first time in a
project at all? Run the following commands.

```
mono clean        # Remove any previously build artifacts
mono unbootstrap  # Remove all dependencies
mono bootstrap    # Reinstall all dependencies

# Run a command
mono build        # Test if the package(s) build succesfully
```

## Publishing a package with mono

Are you ready to publish a new version of package(s) with mono? Run the
following commands.

See the [publish command](../README.md#publish) for more information about
publishing and prereleases.

```
git pull        # Make sure you have the latest changes of the project
mono bootstrap  # Install latest dependencies
mono build      # Make sure it still works (also check the CI build)
mono publish    # Publish the package (will ask for confirmation)
```
