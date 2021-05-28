# frozen_string_literal: true

module ProjectHelper
  EXAMPLES_DIR = "spec/support/examples/"
  EXAMPLES_TMP_DIR = "spec/tmp/examples/"

  def current_project
    unless defined?(@current_project)
      raise "No project selected. Please call `prepare_project(:example_project)` first."
    end

    "#{@current_project}_project"
  end

  def clear_selected_project!
    @current_project = nil
  end

  def select_project(project)
    @current_project = project
  end

  def current_project_dir
    File.join(EXAMPLES_TMP_DIR, current_project)
  end

  def prepare_project(project)
    select_project project
    prepare_tmp_examples_dir
    # Copy example to test dir
    tmp_path = File.join(EXAMPLES_TMP_DIR, current_project)
    FileUtils.cp_r(File.join(EXAMPLES_DIR, current_project), tmp_path)
    init_project
  end

  def prepare_new_project
    select_project "custom_project"
    prepare_tmp_examples_dir
    # Create new directory
    FileUtils.mkdir_p current_project_dir
    init_project
    if block_given?
      in_project do
        yield
        commit_changes "Prepared project" if local_changes?
      end
    end
  end

  def in_project(&block)
    # Execute block in test dir
    Dir.chdir(current_project_dir, &block)
  rescue SystemExit => error
    Testing.exit_status = error.status
  end

  # @api private
  def prepare_tmp_examples_dir
    # Create tmp examples dir
    FileUtils.mkdir_p(EXAMPLES_TMP_DIR)
    # Remove existing test dir
    project_dir = current_project_dir
    # Remove existing project dir if it exists
    FileUtils.rm_r(project_dir) if Dir.exist?(project_dir)
  end

  # @api private
  def init_project
    in_project do
      git_init_directory
      File.open ".gitignore", "w" do |file|
        file.write <<~IGNORE
          # Multiple languages
          *.lock
          tmp

          # Ruby
          *.gem
          .bundle
          vendor

          # Node.js
          package-lock.json
          node_modules/

          # Elixir
          deps
          _build
        IGNORE
      end
      commit_changes "Initial commit"
    end
  end

  def in_package?
    defined? @current_package
  end

  def current_package
    @current_package
  end

  def in_package(package, &block)
    @current_package = package.to_s
    Dir.chdir(current_project_package_dir, &block)
  ensure
    @current_package = nil
  end

  def create_package(package)
    FileUtils.mkdir_p(project_package_path(package))
    in_package(package) do
      create_changelog
      yield
    end
  end

  def current_project_package_dir
    File.join("packages", current_package)
  end

  def project_package_path(package)
    File.join("packages", package.to_s)
  end

  def package_path(package)
    File.join(current_project_dir, "packages", package)
  end

  def create_changelog
    File.open "CHANGELOG.md", "w" do |file|
      file.write <<~IGNORE
        # #{current_package} Changelog

        ## 0.0.0

        - Change 1
        - Change 2
        - Change 3
      IGNORE
    end
  end

  def create_package_json(custom_config)
    File.open("package.json", "w") do |file|
      config = {
        :name => in_package? ? current_package : "",
        :main => "index.js",
        :version => "1.2.3",
        :scripts => {}
      }.merge(custom_config)
      config[:scripts][:build] ||= "echo run build"
      config[:scripts][:test] ||= "echo run test"
      config[:scripts][:clean] ||= "echo run clean"
      file.write("#{JSON.pretty_generate(config)}\n")
    end
  end

  def create_ruby_package_files(custom_config)
    File.open("Gemfile", "w") do |file|
      contents = <<~CONTENTS
        source "https://rubygems.org"

        gemspec

      CONTENTS
      file.write(contents)
    end
    FileUtils.mkdir_p "lib/example/"
    File.open("lib/example/version.rb", "w") do |file|
      contents = <<~CONTENTS
        module Example
          VERSION = "#{custom_config[:version]}"
        end

      CONTENTS
      file.write(contents)
    end
    name = custom_config.fetch(:name, "mygem")
    File.open("#{name}.gemspec", "w") do |file|
      dependencies =
        custom_config.fetch(:dependencies, []).map do |dependency, version|
          %(gem.add_dependency "#{dependency}", "#{version}")
        end
      spec = <<~GEMSPEC
        require_relative "./lib/example/version.rb"

        Gem::Specification.new do |gem| # rubocop:disable Metrics/BlockLength
          gem.authors       = ["Tom de Bruijn"]
          gem.email         = ["test@email.com"]
          gem.description   = "Gem description"
          gem.summary       = "Gem summary"
          gem.homepage      = "https://github.com/appsignal/test-package"
          gem.license       = "MIT"

          gem.files         = Dir.glob("lib/**/*.rb")
          gem.name          = "#{name}"
          gem.require_paths = %w[lib]
          gem.version       = Example::VERSION

          #{dependencies.join("\n  ")}
        end

      GEMSPEC
      file.write(spec)
    end
  end

  def create_package_mix(custom_config) # rubocop:disable Metrics/MethodLength
    File.open("mix.exs", "w") do |file|
      dependencies =
        custom_config.fetch(:dependencies, []).map do |dependency, version|
          %({:#{dependency}, "#{version}"})
        end
      spec = <<~SPEC
        defmodule MyPackage.Mixfile do
          use Mix.Project

          @source_url "https://github.com/appsignal/test-package"
          @version "#{custom_config.fetch(:version)}"

          def project do
            [
              app: :#{in_package? ? current_package : current_project},
              version: @version,
              name: "My Package",
              description: "Dummy package description",
              package: package(),
              homepage_url: "https://appsignal.com",
              elixir: "~> 1.9",
              deps: deps(),
              docs: [
                main: "readme",
                source_ref: @version,
                source_url: @source_url,
                extras: ["CHANGELOG.md"]
              ],
              dialyzer: [
                ignore_warnings: "dialyzer.ignore-warnings",
                plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
              ]
            ]
          end

          defp package do
            %{
              files: [
                "*.md"
              ],
              maintainers: ["Tom de Bruijn"],
              licenses: ["MIT"],
              links: %{
                "Changelog" => "\#{@source_url}/blob/main/CHANGELOG.md",
                "GitHub" => @source_url
              }
            }
          end

          defp deps do
            [
              #{dependencies.join(",\n      ")}
            ]
          end
        end

      SPEC
      file.write(spec)
    end
  end

  def config_for(project)
    Mono::Config.new(
      YAML.safe_load(File.read(File.join(ROOT_DIR, EXAMPLES_DIR, "#{project}_project", "mono.yml")))
    )
  end

  def create_mono_config(config)
    File.open("mono.yml", "w") do |file|
      config["repo"] = "https://github.com/appsignal/#{current_project}"
      file.write YAML.dump(config)
    end
  end

  # Add a hook to the mono.yml config file in the currently selected project
  # {current_project}. It has be prepared {prepare_project} beforehand.
  #
  # @command [String] the type of command to add the hook to.
  # @hook_type [String] either "pre" (before) or "post" (after).
  # @hook_command [String] the command to run in this hook.
  def add_hook(command, hook_type, hook_command)
    config_file = File.join(ROOT_DIR, EXAMPLES_TMP_DIR, current_project, "mono.yml")
    config = YAML.safe_load(File.read(config_file))
    config[command] ||= {}
    config[command][hook_type] = hook_command
    update_config(config)
  end

  def configure_command(command, custom_command)
    config_file = File.join(ROOT_DIR, EXAMPLES_TMP_DIR, current_project, "mono.yml")
    config = YAML.safe_load(File.read(config_file))
    config[command] ||= {}
    config[command]["command"] = custom_command
    update_config(config)
  end

  def update_config(new_config)
    config_file = File.join(ROOT_DIR, EXAMPLES_TMP_DIR, current_project, "mono.yml")
    File.open(config_file, "w") do |file|
      file.write(YAML.dump(new_config))
    end
  end

  def package_for(package, config)
    Mono::Languages::Nodejs::Package.new(package, File.join("packages", package), config)
  end

  def remove_script_from_package_json(command)
    package_json = JSON.parse(File.read(File.join(Dir.pwd, "package.json")))
    package_json["scripts"].delete(command)
    update_package_json(package_json)
  end

  def update_package_json(new_config)
    package_json = File.join(Dir.pwd, "package.json")
    File.open(package_json, "w") do |file|
      file.write(JSON.dump(new_config))
    end
  end
end
