# frozen_string_literal: true

module Mono
  class VersionPromoter
    class UnsupportedDowngradeError < Mono::Error
      def initialize(current_prerelease_type, new_prerelease_type)
        @current_prerelease_type = current_prerelease_type
        @new_prerelease_type = new_prerelease_type
        super()
      end

      def message
        current_type = @current_prerelease_type
        new_type = @new_prerelease_type
        <<~MESSAGE
          Unexpected downgrade for prelease. Can't downgrade from a
          `#{current_type}` to a `#{new_type}`.

          - Current prerelease type: #{current_type}
          - New prerelease type:     #{new_type}
        MESSAGE
      end
    end

    # List of prereleases _in reverse order_.
    RELEASE_VERSIONS = %w[major minor patch].freeze
    PRERELEASE_VERSIONS = %w[rc beta alpha].freeze

    def self.promote(version, bump, prerelease_bump = nil)
      segments =
        if version.prerelease?
          major, minor, patch, prerelease_type, prerelease_version =
            if larger_bump?(version.prerelease_bump.to_s, bump.to_s)
              promote_base(version, bump)
            else
              # If it currently already is a prerelease don't bump the base
              # version. The biggest version bump is leading.
              # Examples:
              # - 1.2.3-alpha.1 + bump minor = 1.3.0.alpha.1 - Base bump
              # - 2.3.0-alpha.1 + bump minor = 2.3.0.alpha.2 - No base bump
              # - 3.0.0-alpha.1 + bump minor = 3.0.0.alpha.2 - No base bump
              version.segments
            end
          prerelease =
            if supported_prerelease_bump?(prerelease_type, prerelease_bump)
              # Bump prerelease
              # Examples:
              # - alpha.1 => alpha.2
              # - alpha.2 => alpha.3
              # - alpha.3 => beta.1
              # - beta.1  => rc.1
              promote_prerelease(
                [prerelease_type, prerelease_version],
                prerelease_bump
              )
            else
              # Error on downgrade of prerelease type.
              # If the requested prerelease type is lower than the current
              # prerelease type raise an error.
              # Examples:
              # - alpha => alpha = OK
              # - alpha => beta  = OK
              # - alpha => rc    = OK
              # - beta  => alpha = ERROR
              # - beta  => rc    = OK
              # - rc    => alpha = ERROR
              # - rc    => beta  = ERROR
              # - rc    => rc    = OK
              # If the current release is an RC and you want to release an
              # alpha, that's not currently supported.
              raise UnsupportedDowngradeError.new(
                prerelease_type,
                prerelease_bump
              )
            end
          [major, minor, patch] + prerelease
        else
          # Normal base release
          promote_base(version, bump)
        end

      Version.new(*segments)
    end

    def self.promote_base(version, bump)
      major = version.major
      minor = version.minor
      patch = version.patch

      case bump
      when "major"
        [major + 1, 0, 0]
      when "minor"
        [major, minor + 1, 0]
      when "patch"
        [major, minor, patch + 1]
      end
    end

    # Allow the user to specify the type via the command line
    # options, e.g. --prerelease beta
    def self.promote_prerelease(prerelease_array, prerelease_bump)
      prerelease_type, prerelease_version = prerelease_array

      if prerelease_type == prerelease_bump
        # Next prerelease of this type: Autoincrement the version number
        [prerelease_type, prerelease_version + 1]
      else
        # First prerelease of this type
        [prerelease_bump, 1]
      end
    end

    def self.larger_bump?(current, new)
      current_index = RELEASE_VERSIONS.index(current)
      new_index = RELEASE_VERSIONS.index(new)
      # Test against reverse order of array values
      new_index < current_index
    end

    def self.supported_prerelease_bump?(current, new)
      current_index = PRERELEASE_VERSIONS.index(current)
      # When no current prelease is specified we support any level bump to a
      # new kind of prerelease type
      return true unless current_index

      new_index = PRERELEASE_VERSIONS.index(new)
      # Test against reverse order of array values
      new_index <= current_index
    end
  end
end
