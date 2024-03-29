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
              Version::Semver.parse(matches[1])
            end
        end

        def update_spec
          contents = read_package_json
          contents =
            contents.sub(VERSION_REGEX, %("version": "#{next_version}"))
          @updated_dependencies.each do |dep, version|
            contents =
              contents.sub(
                /"#{dep}": ".*"/,
                %("#{dep}": "=#{version}")
              )
          end
          File.write(package_json_path, contents)
        end

        def dependencies
          @dependencies ||=
            begin
              deps = @package_json.fetch("dependencies", {})
              optional_deps = @package_json.fetch("optionalDependencies", {})
              dev_deps = @package_json.fetch("devDependencies", {})
              deps.merge(optional_deps).merge(dev_deps)
            end
        end

        def bootstrap_package(_options = {})
          run_client_command_in_package "link"
        end

        def publish_package
          options = []
          if tag?
            options << "--tag #{tag}"
          elsif next_version.prerelease?
            options << "--tag #{next_version.prerelease_type}"
          end
          options << "--new-version #{next_version}" if npm_client == "yarn"
          run_client_command_in_package "publish #{options.join(" ")}".strip,
            :retry => true
        end

        def build_package
          check_if_command_exists!("build")

          run_client_command_for_package "run build"
        end

        def test_package
          check_if_command_exists!("test")

          run_client_command_for_package "run test"
        end

        def clean_package
          check_if_command_exists!("clean")

          run_client_command_for_package "run clean"
        end

        def unbootstrap_package
          run_command_in_package "rm -rf node_modules"
        end

        private

        VERSION_REGEX = /"version": "(.*)"/

        def read_package_json
          File.read(package_json_path)
        end

        def package_json_path
          package_path("package.json")
        end

        def check_if_command_exists!(command)
          return if command_configured?(command)

          raise NoSuchCommandError, command
        end

        def command_configured?(command)
          @package_json.fetch("scripts", {}).key?(command)
        end

        def run_client_command(command)
          run_command "#{npm_client} #{command}"
        end

        def run_client_command_in_package(command, options = {})
          run_command_in_package "#{npm_client} #{command}", options
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
