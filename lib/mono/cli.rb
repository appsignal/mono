# frozen_string_literal: true

require "pathname"

module Mono
  module Cli
    module Helpers
      def ask_for_input
        value = $stdin.gets
        value ? value.chomp : ""
      rescue Interrupt
        puts "\nExiting..."
        exit 1
      end

      def required_input(prompt)
        loop do
          print prompt
          value = ask_for_input
          return value unless value.empty?
        end
      end

      def yes_or_no(prompt, options = {})
        loop do
          print prompt
          input = ask_for_input.strip
          input = options[:default] if input.empty? && options[:default]
          case input
          when "y", "Y", "yes"
            return true
          when "n", "N", "no"
            return false
          end
        end
      end
    end

    class Base
      include Helpers
      include Command::Helper

      def initialize(options = [])
        @options = options
        @config = Config.new
        package_class = PackageBase.for(config.language)
        if config.monorepo?
          packages_dir = config.packages_dir
          @packages =
            Dir.glob("*", :base => packages_dir).map do |package|
              path = File.join(packages_dir, package)
              next unless File.directory?(path)

              package_class.new(package, path, @config)
            end.compact
        else
          # Single package repo
          pathname = Pathname.new(Dir.pwd)
          package = pathname.basename
          @packages = [package_class.new(package, ".", @config)]
        end
      end

      private

      attr_reader :options, :config, :packages

      def packages_to_publish
        packages.select(&:will_update?)
      end

      def run_hooks(command, type)
        hooks = config.hooks(command, type)
        return unless hooks.any?

        puts "Running hooks: #{command}: #{type}"
        hooks.each do |hook|
          run_command hook
        end
      end

      def current_branch
        `git rev-parse --abbrev-ref HEAD`.chomp
      end

      def local_changes?
        `git status -s -u`.split("\n").each do |change|
          change.gsub!(/^.. /, "")
        end.any?
      end

      def chdir(dir, &block)
        puts "cd #{dir}"
        Dir.chdir(dir, &block)
      end

      def exit_cli(message)
        puts message
        exit 1
      end
    end
  end
end

Dir.glob("cli/*", :base => __dir__).each do |file|
  require "mono/#{file}"
end
