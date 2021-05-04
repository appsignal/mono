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
          @packages =
            Dir.glob("*", :base => packages_dir).sort.map do |package|
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
    end

    class Wrapper
      def initialize(command, options)
        @command = command.to_sym
        @options = options
      end

      def execute # rubocop:disable Metrics/CyclomaticComplexity
        case @command
        when :init
          Mono::Cli::Init.new({}).execute
        when :bootstrap
          Mono::Cli::Bootstrap.new({}).execute
        when :clean
          Mono::Cli::Clean.new({}).execute
        when :build
          Mono::Cli::Build.new({}).execute
        when :test
          Mono::Cli::Test.new({}).execute
        when :publish
          Mono::Cli::Publish.new(parsed_options).execute
        when :changeset
          Mono::Cli::Changeset.new({}).execute
        when :run
          Mono::Cli::Custom.new({}).execute
        else
          puts "Unknown command: #{@command}"
          exit 1
        end
      rescue Mono::Error => error
        puts "An error was encountered during the `mono #{@command}` " \
          "command. Stopping operation."
        puts
        puts "#{error.class}: #{error.message}"
        exit 1
      end

      def parsed_options
        params = {}
        {
          :publish => OptionParser.new do |opts|
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
          end
        }.fetch(@command).parse(@options)
        params
      end
    end
  end
end

Dir.glob("cli/*", :base => __dir__).each do |file|
  require "mono/#{file}"
end
