# frozen_string_literal: true

module Mono
  module Cli
    class Bootstrap < Base
      def execute
        puts "Bootstrapping project"
        run_hooks("bootstrap", "pre")
        case config.language
        when "ruby", "elixir"
          bootstrap_generic
        when "nodejs"
          bootstrap_nodejs
        else
          puts "Error: Unknown language configured"
          exit 1
        end
        run_hooks("bootstrap", "post")
      end

      def bootstrap_generic
        packages.each do |package|
          puts "# Bootstrapping package: #{package.name} (#{package.path})"
          package.bootstrap
        end
      end

      def bootstrap_nodejs
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

        run_command "#{npm_client} install"
      end

      def npm_client
        if config.config?("npm_client")
          config.config("npm_client")
        else
          "npm"
        end
      end
    end
  end
end
