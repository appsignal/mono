# frozen_string_literal: true

require "yaml"
require "pathname"
require "optparse"

module Mono
  module Cli
    class Base
      include Shell
      include Command::Helper

      def initialize(options = {})
        @options = options
        @config = Config.new(YAML.safe_load(File.read("mono.yml")))
        @language = Language.for(config.language).new(config)
        find_packages
        validate(options)
      end

      def packages
        dependency_tree.packages
      end

      def dependency_tree
        @dependency_tree ||= DependencyTree.new(@packages)
      end

      private

      attr_reader :options, :config, :language

      def find_packages
        package_class = PackageBase.for(config.language)
        if config.monorepo?
          packages_dir = config.packages_dir
          directories = Dir.glob("*", :base => packages_dir)
            .sort
            .select { |pkg| File.directory?(File.join(packages_dir, pkg)) }
          if language.respond_to? :select_packages
            directories = language.select_packages(directories)
          end

          selected_packages = options[:packages]
          @packages = []
          directories.each do |package|
            path = File.join(packages_dir, package)
            package = package_class.new(package, path, config)
            if selected_packages && !selected_packages.include?(package.name)
              next
            end

            @packages << package
          end
        else
          # Single package repo
          pathname = Pathname.new(Dir.pwd)
          package = pathname.basename
          @packages = [package_class.new(package, ".", config)]
        end
      end

      def validate(options)
        selected_packages = options[:packages]
        if config.monorepo? && selected_packages
          selected_packages.each do |package_name|
            next if packages.find { |package| package.name == package_name }

            # One of the selected packages was not found. Exit mono.
            raise PackageNotFound, package_name
          end
        end
      end

      def run_hooks(command, type)
        hooks = config.hooks(command, type)
        return unless hooks.any?

        puts "Running hooks: #{command}: #{type}"
        hooks.each do |hook|
          run_command hook
        end
      end

      def parallel?
        options[:parallel]
      end

      def current_branch
        `git rev-parse --abbrev-ref HEAD`.chomp
      end

      def local_changes?
        `git status -s -u`.split("\n").each do |change|
          change.gsub!(/^.. /, "")
        end.any?
      end

      def exit_cli(message)
        raise Mono::Error, message
      end

      def exit_with_status(status)
        puts "Exiting..."
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

      def execute_command
        command = @options.shift
        case command
        when "init"
          Mono::Cli::Init.new.execute
        when "bootstrap"
          Mono::Cli::Bootstrap.new(bootstrap_options).execute
        when "unbootstrap"
          Mono::Cli::Unbootstrap.new(unbootstrap_options).execute
        when "clean"
          Mono::Cli::Clean.new(clean_options).execute
        when "build"
          Mono::Cli::Build.new(build_options).execute
        when "test"
          Mono::Cli::Test.new(test_options).execute
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
          Mono::Cli::Custom.new(*custom_options).execute
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
      rescue Interrupt
        puts "User interrupted command. Exiting..."
        exit 1
      end

      private

      AVAILABLE_COMMANDS = %w[
        init
        bootstrap
        unbootstrap
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

      def unbootstrap_options
        params = {}
        OptionParser.new do |opts|
          opts.banner = "Usage: mono unbootstrap [options]"
        end.parse(@options)
        params
      end

      def clean_options
        params = {}
        OptionParser.new do |opts|
          opts.banner = "Usage: mono clean [options]"

          opts.on "-p", "--package package1,package2,package3", Array,
            "Select packages to clean" do |value|
            params[:packages] = value
          end
        end.parse(@options)
        params
      end

      def build_options
        params = {}
        OptionParser.new do |opts|
          opts.banner = "Usage: mono build [options]"

          opts.on "-p", "--package package1,package2,package3", Array,
            "Select packages to build" do |value|
            params[:packages] = value
          end
        end.parse(@options)
        params
      end

      def test_options
        params = {}
        OptionParser.new do |opts|
          opts.banner = "Usage: mono test [options]"

          opts.on "-p", "--package package1,package2,package3", Array,
            "Select packages to test" do |value|
            params[:packages] = value
          end
        end.parse(@options)
        params
      end

      def publish_options
        params = {}
        OptionParser.new do |opts|
          opts.banner = "Usage: mono publish [options]"

          opts.on "-p", "--package package1,package2,package3", Array,
            "Select packages to publish" do |value|
            params[:packages] = value
          end
          opts.on "--alpha", "Release an alpha prerelease" do
            params[:prerelease] = "alpha"
          end
          opts.on "--beta", "Release a beta prerelease" do
            params[:prerelease] = "beta"
          end
          opts.on "--rc", "Release a rc prerelease" do
            params[:prerelease] = "rc"
          end
          opts.on "--tag TAG",
            "Set the tag for the package release (Node.js only)" do |tag|
            params[:tag] = tag
          end
        end.parse(@options)
        params
      end

      def custom_options
        params = {}
        OptionParser.new do |opts|
          opts.banner = "Usage: mono run [options] -- <command>"

          opts.on "-p", "--package package1,package2,package3", Array,
            "Select packages to run command in" do |value|
            params[:packages] = value
          end
          opts.on "--[no-]parallel", "Run commands in parallel" do |value|
            params[:parallel] = value
          end
        end.parse!(@options)
        [@options, params]
      end
    end
  end
end

Dir.glob("cli/*", :base => __dir__).each do |file|
  require "mono/#{file}"
end
