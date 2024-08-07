# frozen_string_literal: true

module Mono
  module Cli
    class Init
      include Shell

      def initialize(options = {})
        @options = options
      end

      def execute
        config = {}
        puts "Initializing project..."
        loop do
          config["language"] = required_input("Language (ruby/elixir/nodejs): ")
          begin
            Language.for(config["language"]) # Check if language is known
            break
          rescue UnknownLanguageError
            puts "Unknown language `#{config["language"]}`"
          end
        end

        print "Packages directory (leave empty for single package repo): "
        packages_dir = ask_for_input
        if packages_dir.empty?
          puts "Configuring for single package repo."
        else
          puts "Configuring for mono package repo."
          config["packages_dir"] = packages_dir
        end
        puts "Writing config file."
        File.write(File.join(Dir.pwd, "mono.yml"), YAML.dump(config))
        puts "Mono config file created!"
        puts "Please see the mono project README for additional config options."
      end
    end
  end
end
