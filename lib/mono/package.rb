# frozen_string_literal: true

module Mono
  class PackageBase
    def self.for(language)
      case language
      when "nodejs"
        Languages::Nodejs::Package
      when "elixir"
        Languages::Elixir::Package
      when "ruby"
        Languages::Ruby::Package
      else
        raise "Unknown language. Please configure `mono.yml` with a `language`."
      end
    end

    include Command::Helper

    attr_reader :path, :name
    attr_accessor :prerelease

    def initialize(name, path, config)
      @path = path
      @name = name
      @config = config
    end

    def next_version
      VersionPromoter.promote(
        current_version,
        changesets.next_bump,
        prerelease
      )
    end

    def next_bump
      changesets.next_bump
    end

    def will_update?
      next_bump
    end

    def changesets
      @changesets ||= ChangesetCollection.new(config, self)
    end

    def tag_prefix
      return unless @config.config?("tag_prefix")

      @config.config("tag_prefix")
    end

    def current_tag
      version = current_version
      if config.monorepo?
        "#{tag_prefix}#{name}@#{version}"
      else # Single repo
        "v#{version}"
      end
    end

    def next_tag
      version = next_version
      if config.monorepo?
        "#{tag_prefix}#{name}@#{version}"
      else # Single repo
        "v#{version}"
      end
    end

    def current_version
      raise NotImplementedError
    end

    def write_new_version
      raise NotImplementedError
    end

    def bootstrap(options = {})
      if config.command?("bootstrap")
        # Custom command configured
        run_command_in_package config.command("bootstrap")
      else
        bootstrap_package(options)
      end
    end

    def build
      if config.command?("build")
        # Custom command configured
        run_command_in_package config.command("build")
      else
        build_package
      end
    end

    def publish_next_version
      if config.command?("publish")
        # Custom command configured
        run_command_in_package config.command("publish")
      else
        publish_package
      end
    end

    def test
      if config.command?("test")
        # Custom command configured
        run_command_in_package config.command("test")
      else
        test_package
      end
    end

    def clean
      if config.command?("clean")
        # Custom command configured
        run_command_in_package config.command("clean")
      else
        clean_package
      end
    end

    def run_custom_command(command)
      run_command_in_package command
    end

    private

    attr_reader :config

    # :nocov:
    def bootstrap_package
      raise NotImplementedError
    end

    def publish_package
      raise NotImplementedError
    end

    def build_package
      raise NotImplementedError
    end

    def clean_package
      raise NotImplementedError
    end
    # :nocov:

    def run_command_in_package(command)
      run_command command, :dir => path
    end
  end
end
