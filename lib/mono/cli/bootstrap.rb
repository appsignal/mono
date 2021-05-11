# frozen_string_literal: true

module Mono
  module Cli
    class Bootstrap < Base
      def execute
        puts "Bootstrapping project"
        run_hooks("bootstrap", "pre")
        bootstrap_language
        bootstrap_packages
        run_hooks("bootstrap", "post")
      end

      def bootstrap_language
        language.bootstrap(:ci => options[:ci])
      end

      def bootstrap_packages
        packages.each do |package|
          puts "# Bootstrapping package: #{package.name} (#{package.path})"
          package.bootstrap(:ci => options[:ci])
        end
      end
    end
  end
end
