# frozen_string_literal: true

module Mono
  module Languages
    module Elixir
      class Package < PackageBase
        def current_version
          @current_version ||=
            begin
              contents = read_mix_exs
              matches = VERSION_REGEX.match(contents)
              Version.parse(matches[2])
            end
        end

        def dependencies
          return @dependencies if defined? @dependencies

          @dependencies = {}
          contents = read_mix_exs
          contents.lines.each do |line|
            matches = DEPENDENCY_REGEX.match(line)
            @dependencies[matches[1]] = matches[2] if matches
          end
          @dependencies
        end

        def update_spec
          contents = read_mix_exs
          new_contents =
            contents.sub(VERSION_REGEX, "\\1 \"#{next_version}\"\\3")
          File.open(mix_exs_path, "w+") do |file|
            file.write new_contents
          end
        end

        def bootstrap_package(_options = {})
          run_command_in_package "mix deps.get"
        end

        def publish_package
          run_command_in_package "mix hex.publish --yes"
        end

        def build_package
          run_command_in_package "mix compile"
        end

        def test_package
          run_command_in_package "mix test"
        end

        def clean_package
          run_command_in_package "rm -rf _build"
        end

        def unbootstrap_package
          run_command_in_package "mix deps.clean --all && mix clean"
        end

        private

        VERSION_REGEX = /(@version|version:) "(.*)"(,?)$/.freeze
        DEPENDENCY_REGEX = /^\s*{:(.*), "(.*)"}/.freeze

        def read_mix_exs
          File.read(mix_exs_path)
        end

        def mix_exs_path
          package_path("mix.exs")
        end
      end
    end
  end
end
