# frozen_string_literal: true

module Mono
  module Languages
    module Nodejs
      class Language < Language::Base
        include ClientHelper

        def select_packages(directories)
          directories.select do |dir|
            File.exist?(File.join(config.packages_dir, dir, "package.json"))
          end
        end

        def bootstrap(options = {})
          case npm_client
          when "npm"
            # TODO: Use `run_command` and capture the output? This way we can
            # mock it in testing.
            output = `npm --version`.chomp
            if !$?.success? ||
                Gem::Version.new(output) < Gem::Version.new("7.0.0")
              puts "npm is older than version 7. " \
                "Updating npm for workspaces support."
              run_command "npm install --global npm"
            end
          when "yarn"
            # TODO: Use `run_command` and capture the output? This way we can
            # mock it in testing.
            output = `yarn --version`.chomp
            if !$?.success? ||
                Gem::Version.new(output) < Gem::Version.new("1.0.0")
              puts "yarn is older than version 1. " \
                "Updating yarn for workspaces support."
              run_command "npm install --global yarn"
            end
          else
            raise "Unknown npm_client: #{npm_client}"
          end

          run_command "#{npm_client} #{install_cmd(:ci => options[:ci])}"
        end

        def clean(_options = {})
          # noop
        end

        def unbootstrap(_options = {})
          run_command "rm -rf node_modules"
        end

        private

        def install_cmd(ci: false)
          case npm_client
          when "npm"
            ci ? "ci" : "install"
          else
            "install"
          end
        end
      end
    end
  end
end
