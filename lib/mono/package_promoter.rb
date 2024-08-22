# frozen_string_literal: true

require "set"

module Mono
  class PackagePromoter
    def initialize(dependency_tree, prerelease: nil)
      @dependency_tree = dependency_tree
      @prerelease = prerelease
      @updated_packages = Set.new
    end

    # Find packages that will be updated, and update packages that depend on
    # those packages to use the updated version of that package.
    def changed_packages
      @changed_packages ||=
        begin
          # Track which packages have registered changes and require an update
          packages_with_changes = []
          packages = dependency_tree.packages

          # Make a registry of packages that require a new release
          packages.each do |package|
            if package.will_update?
              packages_with_changes << package
              updated_packages << package
            end
          end

          # If there are no registered changes (changesets) and it's a new base
          # release, update packages that are currently prereleases.
          # This covers the scenario where you did a prerelease, no further
          # fixes/changes are needed and the latest prerelease will become the
          # final release.
          unless prerelease?
            packages.each do |package|
              next unless package.current_version.prerelease?

              package.bump_version_to_final
              packages_with_changes << package
              updated_packages << package
            end
          end

          # Find packages that depend on the updated packages
          packages_with_changes.each do |updated_package|
            update_package_and_dependents(updated_package)
          end

          updated_packages
        end
    end

    private

    attr_reader :dependency_tree, :updated_packages, :prerelease

    alias prerelease? prerelease

    def update_package_and_dependents(package)
      dependency_tree[package.name][:dependents].each do |dependent|
        dependent_package = dependency_tree[dependent][:package]
        # Update the updated package this package depends upon.
        # This way they have a changeset registered on them that makes it aware
        # it will be updated as well.
        dependent_package.update_dependency package
        # Track the updater for writing changes
        updated_packages << dependent_package
        # Also update any packages that depend on this package
        update_package_and_dependents(dependent_package)
      end
    end
  end
end
