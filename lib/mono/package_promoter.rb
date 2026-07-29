# frozen_string_literal: true

require "set"

module Mono
  class PackagePromoter
    def initialize(dependency_tree, prerelease: nil, version_lock: false)
      @dependency_tree = dependency_tree
      @prerelease = prerelease
      @version_lock = version_lock
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

          force_version_lock(packages) if version_lock?

          updated_packages
        end
    end

    private

    attr_reader :dependency_tree, :updated_packages, :prerelease, :version_lock

    alias prerelease? prerelease
    alias version_lock? version_lock

    # With a version lock, every package in the repository releases together at
    # one shared version. Each package that would not otherwise reach the shared
    # bump gets a synthetic changeset at that bump, so its next version lands on
    # the same number as the rest.
    def force_version_lock(packages)
      return if updated_packages.empty?

      assert_no_version_drift!(packages)

      bump = coupled_bump(packages)
      return unless bump

      triggers = packages.select do |package|
        package.next_bump && bump_index(package.next_bump) <= bump_index(bump)
      end
      version = triggers.first.next_version

      packages.each do |package|
        current_bump = package.next_bump
        next if current_bump && bump_index(current_bump) <= bump_index(bump)

        package.changesets.changesets <<
          VersionLockMemoryChangeset.new(bump, triggers, version)
        updated_packages << package
      end
    end

    # A version lock only forces packages that already sit at the same version
    # onto a shared next version. If they have drifted apart, forcing them would
    # hide a mistake, so raise instead.
    def assert_no_version_drift!(packages)
      reference = packages.first.current_version
      in_step = packages.all? do |package|
        reference.eql?(package.current_version)
      end
      return if in_step

      versions = packages.map do |package|
        "#{package.name} #{package.current_version}"
      end
      raise Mono::Error,
        "Cannot release with `version_lock` because the packages are not at " \
          "the same version. Please bring them back in step and try again.\n" \
          "Current versions: #{versions.join(", ")}"
    end

    def coupled_bump(packages)
      bumps = packages.map(&:next_bump).compact
      bumps.min_by { |bump| bump_index(bump) }
    end

    def bump_index(bump)
      Changeset::SUPPORTED_BUMPS.keys.index(bump)
    end

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
