# frozen_string_literal: true

module Mono
  class Config
    def initialize(config)
      @config = config
    end

    def language
      @config.fetch("language") { raise "No language configured." }
    end

    def repo
      @config.fetch("repo") { raise "No `repo` configured in mono.yml." }
    end

    def packages_dir
      @config["packages_dir"]
    end

    def packages
      @config["packages"]
    end

    def monorepo?
      @config.key?("packages_dir") || @config.key?("packages")
    end

    def version_lock?
      @config.fetch("version_lock", false)
    end

    # Checks the config for problems that mono cannot recover from and raises a
    # clear error for each. Called once when the CLI starts, before any packages
    # are discovered, so a misconfigured repo fails fast.
    def validate!
      if @config.key?("packages_dir") && @config.key?("packages")
        raise Mono::Error,
          "Both `packages_dir` and `packages` are configured in mono.yml. " \
            "These options are mutually exclusive. Please configure only one."
      end

      validate_packages! if @config.key?("packages")
      validate_version_lock!
    end

    def command?(cmd)
      @config.fetch(cmd, {}).key?("command")
    end

    def command(cmd)
      @config.fetch(cmd, {}).fetch("command") do
        raise "Command '#{cmd}.command' not found."
      end
    end

    def hooks(command, type)
      Array(@config.fetch(command, {}).fetch(type, []))
    end

    def publish
      @config.fetch("publish", {})
    end

    def config?(key)
      @config.key?(key)
    end

    def config(key)
      @config.fetch(key) { raise "No config found for key '#{key}'" }
    end

    def version_scheme
      Version::VERSION_SCHEMES[@config["version_scheme"]] || Version::Semver
    end

    def inspect
      @config.inspect
    end

    private

    def validate_packages!
      packages = @config["packages"]
      unless packages.is_a?(Hash) && !packages.empty?
        raise Mono::Error,
          "The `packages` option in mono.yml must be a non-empty map of " \
            "package names to paths."
      end

      unless packages.values.all? { |path| path.is_a?(String) }
        raise Mono::Error,
          "The `packages` option in mono.yml must map every package name to " \
            "a path string."
      end

      # Reject blank names and paths before any path normalization runs. A
      # blank path would normalize to ".", which would silently turn the entry
      # into a root package instead of failing.
      blank = packages.any? do |name, path|
        name.to_s.strip.empty? || path.strip.empty?
      end
      return unless blank

      raise Mono::Error,
        "The `packages` option in mono.yml must not have a blank package " \
          "name or path."
    end

    def validate_version_lock!
      return unless version_lock?
      return if monorepo?

      raise Mono::Error,
        "The `version_lock` option in mono.yml only applies to a repository " \
          "that is configured for multiple packages with `packages` or " \
          "`packages_dir`. Please configure one of those, or remove " \
          "`version_lock`."
    end
  end
end
