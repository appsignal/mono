# frozen_string_literal: true

require "set"

module Mono
  class PackagePromoter
    def initialize(packages)
      @packages = packages
      @updated_packages = Set.new
    end

    # Find packages that will be updated, and update packages that depend on
    # those packages to use the updated version of that package.
    def changed_packages
      @changed_packages ||=
        begin
          build_tree
          # Track which packages have registered changes and require an update
          packages_with_changes = []

          # Make a registry of packages that require a new release
          packages.select do |package|
            if package.will_update?
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

    attr_reader :packages, :tree, :updated_packages

    def update_package_and_dependents(package)
      tree[package.name][:dependents].each do |dependent|
        dependent_package = tree[dependent][:package]
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

    # Build a dependency tree. Track which packages depent on other packages in
    # this project. It creates a tree with dependencies going both ways:
    # dependencies and dependents.
    def build_tree
      @tree =
        Hash.new do |hash, key|
          hash[key] = {
            :package => nil,
            :dependents => [], # List of packages that depend on this package
            :dependencies => [] # List of packages that this package depends on
          }
        end

      package_names = packages.map(&:name)
      # Build a package tree based on dependencies
      packages.each do |package|
        # Only track packages in this project, not other ecosystem dependencies
        next unless package_names.include? package.name

        @tree[package.name][:package] = package
        deps = package.dependencies
        @tree[package.name][:dependencies] = deps.keys if deps
      end
      # Loop through it again to figure out depenents from the dependencies
      packages.each do |package| # rubocop:disable Style/CombinableLoops
        @tree[package.name][:dependencies].each do |dep, _version_lock|
          # Keep track of dependent packages
          @tree[dep][:dependents] << package.name
        end
      end
    end
  end
end
