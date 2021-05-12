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
              Version.parse(matches[1])
            end
        end

        def write_new_version
          contents = read_mix_exs
          new_contents =
            contents.sub(VERSION_REGEX, %(@version "#{next_version}"))
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
          # TODO: Move this to a "nuke" or "unbootstrap" command instead?
          run_command_in_package "mix deps.clean --all && mix clean"
        end

        private

        VERSION_REGEX = /@version "(.*)"$/.freeze

        def read_mix_exs
          File.read(mix_exs_path)
        end

        def mix_exs_path
          File.join(path, "mix.exs")
        end
      end
    end
  end
end
