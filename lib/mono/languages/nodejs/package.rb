# frozen_string_literal: true

require "json"

module Mono
  module Languages
    module Nodejs
      class Package < PackageBase
        include ClientHelper

        def initialize(_name, path, config)
          @package_json = JSON.parse(File.read(File.join(path, "package.json")))
          super(@package_json["name"], path, config)
        end

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

        def bootstrap_package(_options = {})
          chdir { run_client_command "link" }
        end

        def publish_package
          options = " --tag beta" if next_version.prerelease?
          run_client_command_for_package "publish#{options}"
        end

        def build_package
          run_client_command_for_package "run build"
        end

        def test_package
          run_client_command_for_package "run test"
        end

        def clean_package
          # TODO: Move this to a "unbootstrap" command instead?
          run_command_for_package "rm -rf node_modules"
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

        def run_client_command_for_package(command)
          case npm_client
          when "npm"
            options = " --workspace=#{name}" if config.monorepo?
            run_client_command "#{command}#{options}"
          when "yarn"
            if config.monorepo?
              run_client_command "workspace #{name} #{command}"
            else
              run_client_command command
            end
          end
        end
      end
    end
  end
end
