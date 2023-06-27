# frozen_string_literal: true

module Mono
  module Languages
    module Git
      class Package < PackageBase
        def current_version
          version = run_command_in_package(
            "git rev-parse --short=7 HEAD",
            :capture => true,
            :print_command => false
          ).strip

          @current_version ||= Version::Custom.parse(version)
        end

        # Not supported
        def dependencies
          []
        end

        def update_spec
          # noop
        end
      end
    end
  end
end
