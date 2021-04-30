# frozen_string_literal: true

module Mono
  module Cli
    class Bootstrap < Base
      def execute
        puts "Bootstrapping project"
        run_hooks("bootstrap", "pre")
        case config.language
        when "ruby", "elixir", "nodejs"
          bootstrap_language
          bootstrap_packages
        else
          puts "Error: Unknown language configured"
          exit 1
        end
        run_hooks("bootstrap", "post")
      end

      def bootstrap_language
        language.bootstrap
      end

      def bootstrap_packages
        packages.each do |package|
          puts "# Bootstrapping package: #{package.name} (#{package.path})"
          package.bootstrap
        end
      end
    end
  end
end
