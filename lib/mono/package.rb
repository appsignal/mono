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

    def initialize(name, path, config)
      @path = path
      @name = name
      @config = config
    end

    def next_version
      @next_version ||=
        begin
          bump = changesets.next_bump
          major = current_version.major
          minor = current_version.minor
          patch = current_version.patch
          version_segments =
            case bump
            when "major"
              [major + 1, 0, 0]
            when "minor"
              [major, minor + 1, 0]
            when "patch"
              [major, minor, patch + 1]
            else
              # TODO: support alpha, beta and rc releases (prereleases).
              # Allow the user to specify the type via the command line
              # options, e.g. --prerelease beta
              # Auto increment the prerelease version number if it's already a
              # prerelease
              raise "Unknown package bump type: #{bump}"
            end
          Version.new(*version_segments)
        end
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

    def bootstrap
      chdir do
        if config.command?("bootstrap")
          # Custom command configured
          run_command config.command("bootstrap")
        else
          bootstrap_package
        end
      end
    end

    def build
      chdir do
        if config.command?("build")
          # Custom command configured
          run_command config.command("build")
        else
          build_package
        end
      end
    end

    def publish_next_version
      chdir do
        if config.command?("publish")
          # Custom command configured
          command = config.command("publish")
          run_command command
        else
          publish_package
        end
      end
    end

    def test
      chdir do
        if config.command?("test")
          # Custom command configured
          run_command config.command("test")
        else
          test_package
        end
      end
    end

    def clean
      chdir do
        if config.command?("clean")
          # Custom command configured
          run_command config.command("clean")
        else
          clean_package
        end
      end
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

    def chdir(&block)
      Dir.chdir(path, &block)
    end
  end
end
