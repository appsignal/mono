# frozen_string_literal: true

module Mono
  class Version
    # Parse both formats for version numbers using prereleases.
    # The Ruby gem uses a dot (.) between the version number and the
    # prerelease, e.g. "1.2.3.alpha.1".
    # The Elixir and Node.js packages use a dash (-) between the version number
    # and the prerelease, e.g. "1.2.3-alpha.1".
    def self.parse(string, separator: "-")
      string = string.sub(separator, ".")
      major, minor, patch, prerelease_type, prerelease_version =
        Gem::Version.new(string).segments

      new(
        major,
        minor,
        patch,
        prerelease_type,
        prerelease_version,
        :separator => separator
      )
    end

    def self.parse_ruby(string)
      parse(string, :separator => ".")
    end

    attr_reader :major, :minor, :patch, :prerelease_type, :prerelease_version,
      :separator

    def initialize( # rubocop:disable Metrics/ParameterLists
      major,
      minor,
      patch,
      prerelease_type = nil,
      prerelease_version = nil,
      separator: "-"
    )
      @major = major
      @minor = minor
      @patch = patch
      @prerelease_type = prerelease_type
      @prerelease_version = prerelease_version
      @separator = separator
    end

    def prerelease?
      @prerelease_type && @prerelease_version
    end

    def prerelease_bump
      return unless prerelease?

      if minor == 0 && patch == 0 # rubocop:disable Style/NumericPredicate
        # For example: "3.0.0"
        :major
      elsif patch == 0 # rubocop:disable Style/NumericPredicate
        # For example: "3.2.0"
        :minor
      else
        # For example: "3.2.1"
        :patch
      end
    end

    def to_s
      base = [major, minor, patch].join(".")
      if prerelease?
        "#{base}#{separator}#{prerelease_type}.#{prerelease_version}"
      else
        base
      end
    end
  end
end
