# frozen_string_literal: true

module Mono
  class Version
    # The Elixir and Node.js package versions follow the semantic
    # versioning standard, which uses a dash (-) between the version
    # number and the pre-release, e.g. "1.2.3-alpha.1".
    class Semver < Version
      def self.parse(string)
        string = string.sub("-", ".")
        major, minor, patch, prerelease_type, prerelease_version =
          Gem::Version.new(string).segments

        new(major, minor, patch, prerelease_type, prerelease_version)
      end

      def to_s
        base = [major, minor, patch].join(".")
        if prerelease?
          "#{base}-#{prerelease_type}.#{prerelease_version}"
        else
          base
        end
      end
    end

    # The Ruby gem versions use a dot (.) between the version number and the
    # pre-release, e.g. "1.2.3.alpha.1".
    class Ruby < Version
      def self.parse(string)
        major, minor, patch, prerelease_type, prerelease_version =
          Gem::Version.new(string).segments

        new(major, minor, patch, prerelease_type, prerelease_version)
      end

      def to_s
        [major, minor, patch, prerelease_type,
         prerelease_version].compact.join(".")
      end
    end

    # The Python package versions use a custom version scheme, defined in
    # PEP 440, with different pre-release type names, and with no separator
    # between the version, the pre-release type, and the pre-release version,
    # e.g. "1.2.3a1"
    class Python < Version
      # https://peps.python.org/pep-0440/#pre-release-separators
      # This regular expression allows for ".", "-" and "_" as pre-release
      # separators, and allows for a separator between the pre-release type
      # and the pre-release version.
      # It also allows for additional "release" segments beyond major, minor
      # and patch, which are ignored.
      VERSION_MATCHER = /
        ^v?                                              # v      -- ignored
        (?<major>\d+)\.?(?<minor>\d+)?\.?(?<patch>\d+)?  # 1.2.3
        (?:\.\d+)*                                       # .4.5   -- ignored
        (?:
          [.\-_]?                                        # .      -- ignored
          (?<pre_type>a|alpha|b|beta|c|rc|pre|preview)   # rc
          [.\-_]?                                        # .      -- ignored
          (?<pre_version>\d+)?                           # 4
        )?$
      /ix

      # Maps from Mono pre-release types to Python pre-release types.
      PRERELEASE_TYPE_TO_S = {
        "alpha" => "a",
        "beta" => "b",
        "rc" => "rc"
      }.freeze

      # https://peps.python.org/pep-0440/#pre-release-spelling
      # For compatibility, "alpha" is allowed as an alternative form for "a",
      # "beta" is allowed as an alternative form of "b", and all of "c", "pre"
      # and "preview" are allowed as alternative forms of "rc".
      # This map does not normalise those pre-release types to the PEP-defined
      # forms ("a", "b", "rc") but to the ones used throughout Mono ("alpha",
      # "beta", "rc")
      PRERELEASE_TYPE_PARSE = {
        "a" => "alpha",
        "alpha" => "alpha",
        "b" => "beta",
        "beta" => "beta",
        "c" => "rc",
        "pre" => "rc",
        "preview" => "rc",
        "rc" => "rc"
      }.freeze

      def self.parse(string)
        match = VERSION_MATCHER.match(string.strip)
        major, minor, patch, prerelease_type, prerelease_version =
          match.values_at(:major, :minor, :patch, :pre_type, :pre_version)

        if prerelease_type
          prerelease_type = PRERELEASE_TYPE_PARSE[prerelease_type]
          # https://peps.python.org/pep-0440/#implicit-pre-release-number
          # For compatibility, `1.1a` is allowed as a shorthand for `1.1a0`.
          prerelease_version = prerelease_version.to_i
        end

        new(major.to_i, minor.to_i, patch.to_i, prerelease_type,
          prerelease_version)
      end

      def to_s
        base = [major, minor, patch].compact.join(".")
        if prerelease?
          "#{base}#{PRERELEASE_TYPE_TO_S[prerelease_type]}#{prerelease_version}"
        else
          base
        end
      end
    end

    VERSION_SCHEMES = {
      "semver" => Version::Semver,
      "ruby" => Version::Ruby,
      "python" => Version::Python
    }.freeze

    attr_reader :major, :minor, :patch, :prerelease_type, :prerelease_version

    def initialize(
      major,
      minor,
      patch,
      prerelease_type = nil,
      prerelease_version = nil
    )
      @major = major
      @minor = minor
      @patch = patch
      @prerelease_type = prerelease_type
      @prerelease_version = prerelease_version
    end

    # Return a new object of the same class as the current object. This is
    # used to generate a new version object with the same serialisation rules
    # as the current version object.
    def with(*args)
      self.class.new(*args)
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
      raise NoMethodError,
        "the Mono::Version superclass does not implement `to_s`"
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
