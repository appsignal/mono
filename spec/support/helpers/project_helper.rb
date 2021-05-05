# frozen_string_literal: true

module ProjectHelper
  EXAMPLES_DIR = "spec/support/examples/"
  EXAMPLES_TMP_DIR = "spec/tmp/examples/"

  def selected_project
    unless defined?(@project_example)
      raise "No project selected. Please call `#{prepare_project}(:language, :type)` first."
    end

    "#{@project_example}_project"
  end

  def clear_selected_project!
    @project_example = nil
  end

  def prepare_project(project)
    @project_example = project

    prepare_project_example selected_project
  end

  def in_project(&block)
    in_project_example selected_project, &block
  end

  # @api private
  def prepare_project_example(project)
    tmp_path = File.join(EXAMPLES_TMP_DIR, project)
    FileUtils.mkdir_p(EXAMPLES_TMP_DIR)
    # Remove existing test dir
    FileUtils.rm_r(tmp_path) if Dir.exist?(tmp_path)
    # Copy example to test dir
    FileUtils.cp_r(File.join(EXAMPLES_DIR, project), tmp_path)

    in_project_example project do
      run_command "git init ."
      commit_changes "Initial commit"
    end
  end

  # @api private
  def in_project_example(project, &block)
    tmp_path = File.join(EXAMPLES_TMP_DIR, project)
    # Execute block in test dir
    Dir.chdir(tmp_path, &block)
  rescue SystemExit => error
    Testing.exit_status = error.status
  end

  def in_package(package, &block)
    Dir.chdir(File.join("packages", package.to_s), &block)
  end

  def config_for(project)
    Mono::Config.new(
      YAML.safe_load(File.read(File.join(ROOT_DIR, EXAMPLES_DIR, "#{project}_project", "mono.yml")))
    )
  end

  # Add a hook to the mono.yml config file in the currently selected project
  # {selected_project}. It has be prepared {prepare_project} beforehand.
  #
  # @command [String] the type of command to add the hook to.
  # @hook_type [String] either "pre" (before) or "post" (after).
  # @hook_command [String] the command to run in this hook.
  def add_hook(command, hook_type, hook_command)
    config_file = File.join(ROOT_DIR, EXAMPLES_TMP_DIR, selected_project, "mono.yml")
    config = YAML.safe_load(File.read(config_file))
    config[command] ||= {}
    config[command][hook_type] = hook_command
    File.open(config_file, "w") do |file|
      file.write(YAML.dump(config))
    end
  end

  def package_for(package, config)
    Mono::Languages::Nodejs::Package.new(package, File.join("packages", package), config)
  end
end
