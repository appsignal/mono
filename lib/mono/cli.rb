# frozen_string_literal: true

require "yaml"
require "pathname"
require "optparse"

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
        @config = Config.new(YAML.safe_load(File.read("mono.yml")))
        @language = Language.for(config.language).new(config)
        package_class = PackageBase.for(config.language)
        if config.monorepo?
          packages_dir = config.packages_dir
          directories = Dir.glob("*", :base => packages_dir)
            .sort
            .select { |pkg| File.directory?(File.join(packages_dir, pkg)) }
          if @language.respond_to? :select_packages
            directories = @language.select_packages(directories)
          end

          @packages =
            directories.map do |package|
              path = File.join(packages_dir, package)
              package_class.new(package, path, @config)
            end
        else
          # Single package repo
          pathname = Pathname.new(Dir.pwd)
          package = pathname.basename
          @packages = [package_class.new(package, ".", @config)]
        end
      end

      private

      attr_reader :options, :config, :language, :packages

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
        raise Mono::Error, message
      end

      def exit_with_status(status)
        print "Exiting..."
        exit status
      end
    end

    class Wrapper
      def initialize(options)
        @options = options
      end

      def execute
        parse_global_options
        execute_command
      end

      def execute_command # rubocop:disable Metrics/CyclomaticComplexity
        command = @options.shift
        case command
        when "init"
          Mono::Cli::Init.new.execute
        when "bootstrap"
          Mono::Cli::Bootstrap.new(bootstrap_options).execute
        when "clean"
          Mono::Cli::Clean.new.execute
        when "build"
          Mono::Cli::Build.new.execute
        when "test"
          Mono::Cli::Test.new.execute
        when "publish"
          Mono::Cli::Publish.new(publish_options).execute
        when "changeset"
          subcommand = @options.shift
          case subcommand
          when "add"
            Mono::Cli::Changeset::Add.new.execute
          when "status"
            puts "Not implemented in prototype. " \
              "But this would print the next determined version number."
            exit_cli_with_status 1
          end
        when "run"
          Mono::Cli::Custom.new(@options).execute
        else
          puts "Unknown command: #{command}"
          puts "Run `mono --help` for the list of available commands."
          exit_cli_with_status 1
        end
      rescue Mono::Error => error
        puts "A Mono error was encountered during the `mono #{command}` " \
          "command. Stopping operation."
        puts
        puts "#{error.class}: #{error.message}"
        exit_cli_with_status 1
      rescue StandardError => error
        puts "An unexpected error was encountered during the " \
          "`mono #{command}` command. Stopping operation."
        puts
        raise error
      end

      private

      AVAILABLE_COMMANDS = %w[
        init
        bootstrap
        clean
        build
        test
        publish
        changeset
        run
      ].freeze

      def exit_cli_with_status(status)
        exit status
      end

      def parse_global_options
        OptionParser.new do |o|
          o.banner = "Usage: mono <command> [options]"

          o.on "-v", "--version", "Print version and exit" do |_arg|
            puts "Mono #{Mono::VERSION}"
            exit_cli_with_status 0
          end

          o.on "-h", "--help", "Show help and exit" do
            puts o
            exit_cli_with_status 0
          end

          o.separator ""
          o.separator "Available commands: #{AVAILABLE_COMMANDS.join(", ")}"
        end.order!(@options)
      end

      def bootstrap_options
        params = {}
        OptionParser.new do |opts|
          opts.banner = "Usage: mono publish [options]"

          opts.on "--[no-]ci",
            "Bootstrap the project optimized for CI environments" do |value|
            params[:ci] = value
          end
        end.parse(@options)
        params
      end

      def publish_options
        params = {}
        OptionParser.new do |opts|
          opts.banner = "Usage: mono publish [options]"

          opts.on "--alpha", "Release an alpha prerelease" do
            params[:prerelease] = :alpha
          end
          opts.on "--beta", "Release a beta prerelease" do
            params[:prerelease] = :beta
          end
          opts.on "--rc", "Release a rc prerelease" do
            params[:prerelease] = :rc
          end
        end.parse(@options)
        params
      end
    end
  end
end

Dir.glob("cli/*", :base => __dir__).each do |file|
  require "mono/#{file}"
end
