# frozen_string_literal: true

module Mono
  module Cli
    class Init
      include Helpers

      def initialize(_options = [])
      end

      def execute
        config = {}
        puts "Initializing project..."
        config["language"] = required_input("Language (ruby/elixir/nodejs): ")
        print "Packages directory (leave empty for single package repo): "
        packages_dir = ask_for_input
        if packages_dir.empty?
          puts "Configuring for single package repo."
        else
          puts "Configuring for mono package repo."
          config["packages_dir"] = packages_dir
          config["tag_prefix"] = ""
        end
        puts "Writing config file."
        File.open(File.join(Dir.pwd, "mono.yml"), "w+") do |file|
          file.write YAML.dump(config)
        end
      end
    end
  end
end
