# frozen_string_literal: true

module Mono
  module Languages
    module Nodejs
      class Package < PackageBase
        include ClientHelper

        def current_version
          @current_version ||=
            begin
              contents = read_package_json
              matches = VERSION_REGEX.match(contents)
              Version.parse(matches[1])
            end
        end

        def write_new_version
          contents = read_package_json
          new_contents =
            contents.sub(VERSION_REGEX, %("version": "#{next_version}"))
          File.open(package_json_path, "w+") do |file|
            file.write new_contents
          end
        end

        def bootstrap_package
          run_client_command "link"
        end

        def publish_package
          options = " --tag beta" if next_version.prerelease?
          run_client_command "publish#{options}"
        end

        def build_package
          run_client_command "run build"
        end

        def test_package
          run_client_command "run test"
        end

        def clean_package
          # TODO: Move this to a "unbootstrap" command instead?
          run_command "rm -rf node_modules"
        end

        private

        VERSION_REGEX = /"version": "(.*)"/.freeze

        def read_package_json
          File.read(package_json_path)
        end

        def package_json_path
          File.join(path, "package.json")
        end

        def run_client_command(command)
          run_command "#{npm_client} #{command}"
        end
      end
    end
  end
end
