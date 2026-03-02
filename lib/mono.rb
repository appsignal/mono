# frozen_string_literal: true

module Mono
  class Error < StandardError; end

  class PackageNotFound < Error
    def initialize(package, available = [])
      @package = package
      @available = available
      super()
    end

    def message
      msg = "The package with the name `#{@package}` could not be found."
      msg += "\nAvailable packages: #{@available.join(", ")}" if @available.any?
      msg
    end
  end

  class CircularDependencyError < Error
    def initialize(package_names)
      @package_names = package_names
      super()
    end

    def message
      "Circular dependencies detected! Two or more packages are configured " \
        "as circular dependencies of each other.\n" \
        "Packages: #{@package_names.join(", ")}"
    end
  end

  class NoSuchCommandError < Error
    def initialize(command)
      @command = command
      super()
    end

    def message
      "No such command found `#{@command}`"
    end
  end
end

require "mono/utils"
require "mono/shell"
require "mono/version"
require "mono/version_object"
require "mono/version_promoter"
require "mono/dependency_tree"
require "mono/package_promoter"
require "mono/config"
require "mono/command"
require "mono/changeset"
require "mono/changeset_collection"
require "mono/package"
require "mono/languages"
