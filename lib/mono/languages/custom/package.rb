# frozen_string_literal: true

module Mono
  module Languages
    module Custom
      class Package < PackageBase
        def current_version
          @current_version ||=
            if config.config?("read_version")
              version = run_command_in_package(
                config.config("read_version"),
                :capture => true,
                :print_command => false
              ).strip
              config.version_scheme.parse(version)
            else
              raise NotImplementedError,
                "Please add `read_version` config to `mono.yml` file."
            end
        end

        # Not supported
        def dependencies
          []
        end

        def update_spec
          if config.config?("write_version")
            run_command_in_package(
              [
                config.config("write_version"),
                next_version
              ].join(" "),
              :print_command => false
            )
          else
            raise NotImplementedError,
              "Please add `write_version` config to `mono.yml` file."
          end
        end
      end
    end
  end
end
