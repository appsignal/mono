# frozen_string_literal: true

module Mono
  class DependencyTree
    def initialize(packages)
      @raw_packages = packages
      build
    end

    # Fetch package dependency tree entry with its dependencies and dependents
    #
    # @return [Hash<String, Hash<Symbol, Object>]
    def [](name)
      tree[name]
    end

    # Return list of packages in dependency order. The first item has the least
    # amount of dependencies on packages in the project (most likely none) and
    # the last one the most dependencies.
    #
    # @raise [CircularDependencyError] if the project packages have a circular
    #   dependency on one another.
    # @return [Array]
    def packages
      return @packages if defined?(@packages)

      pkgs = []
      unsorted_packages = tree.keys
      iterations = Hash.new { |hash, key| hash[key] = 0 }
      until unsorted_packages.empty?
        package_name = unsorted_packages.shift
        iterations[package_name] += 1
        package = tree[package_name]
        if depdendencies_checked? pkgs, package[:dependencies]
          # Reset iterations for remaining packages so we don't claim it to be
          # a circular dependency when we're still making progress.
          unsorted_packages.each { |pkg| iterations[pkg] = 0 }

          # Dependencies are all ordered, so we can include it in the list next
          pkgs << package_name
        else
          # Dependency not yet ordered, moving to last position to try again
          # later when hopefully all dependencies have been ordered
          unsorted_packages << package_name
        end

        # A package has been looped more than 10 times without resolving any
        # packages, most likely a circular dependency was found.
        next unless iterations[package_name] > 10

        raise CircularDependencyError, unsorted_packages
      end
      @packages = pkgs.map { |name| tree[name][:package] }
    end

    private

    attr_reader :raw_packages, :tree

    def depdendencies_checked?(pkgs, dependencies)
      dep_checks = dependencies.map { |name, _| pkgs.include? name }
      dep_checks.all?(true)
    end

    # Build a dependency tree. Track which packages depend on other packages in
    # this project. It creates a tree with dependencies going both ways:
    # dependencies and dependents.
    def build # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      @tree =
        Hash.new do |hash, key|
          hash[key] = {
            :package => nil,
            :dependents => [], # List of packages that depend on this package
            :dependencies => [] # List of packages that this package depends on
          }
        end

      package_names = raw_packages.map(&:name)
      # Build a package tree based on dependencies
      raw_packages.each do |package|
        # Only track packages in this project, not other ecosystem dependencies
        next unless package_names.include? package.name

        @tree[package.name][:package] = package
        deps = package.dependencies
        next unless deps

        package_deps = {}
        deps.each do |key, value|
          package_deps[key] = value if package_names.include?(key)
        end
        @tree[package.name][:dependencies] = package_deps
      end
      # Loop through it again to figure out dependents from the dependencies
      raw_packages.each do |package| # rubocop:disable Style/CombinableLoops
        @tree[package.name][:dependencies].each do |dep, _version_lock|
          # Only track packages in this project, not other ecosystem
          # dependencies
          next unless package_names.include? dep

          # Keep track of dependent packages
          @tree[dep][:dependents] << package.name
        end
      end
    end
  end
end
