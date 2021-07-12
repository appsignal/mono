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

    def current_bump
      if minor == 0 && patch == 0 # rubocop:disable Style/NumericPredicate
        # For example: "3.0.0"
        "major"
      elsif patch == 0 # rubocop:disable Style/NumericPredicate
        # For example: "3.2.0"
        "minor"
      else
        # For example: "3.2.1"
        "patch"
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

    # Returns segments of the version object
    #
    # When a version has no prerelease information (alpha/beta/rc) the last two
    # elements are omitted.
    #
    # - <Index>: Type of segment
    # - 0: major
    # - 1: minor
    # - 2: patch
    # - 3: prerelease type (alpha, beta, rc) (Optional)
    # - 4: prerelease version number (Optional)
    def segments
      [
        major,
        minor,
        patch,
        prerelease_type,
        prerelease_version
      ].compact
    end

    def eql?(other)
      segments == other.segments
    end
  end
end
