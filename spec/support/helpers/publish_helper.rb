# frozen_string_literal: true

module PublishHelper
  LANGUAGE_PUBLISH_SETUP = {
    :ruby => { :publish_commands => [/^gem push/] },
    :elixir => {
      :publish_commands => [/^mix hex.publish package --yes/],
      :before_commands => [lambda { PublishHelper.run_bootstrap }]
    },
    :nodejs => {
      :publish_commands => [/^(npm|yarn) publish/],
      :before_commands => [lambda { PublishHelper.run_bootstrap }]
    },
    :custom => { :publish_commands => [] },
    :unknown => { :publish_commands => [] }
  }.freeze

  def expect_changelog_to_include_version_header(changelog, version)
    expect(changelog).to include("## #{version}")
  end

  def expect_changelog_to_include_release_notes(changelog, bump, message = nil)
    url = "https://github.com/appsignal/#{current_project}"
    message ||= "This is a #{bump} changeset bump."
    expect(changelog)
      .to match(%r{- \[[a-z0-9]{7}\]\(#{url}/commit/[a-z0-9]{40}\) #{bump} - #{message}})
  end

  def expect_changelog_to_include_message(changelog, bump, message)
    expect(changelog).to match(/- #{bump} - #{message}/)
  end

  def expect_changelog_to_include_package_bump(changelog, package, version)
    message = "Update #{package} dependency to #{version}"
    expect_changelog_to_include_message(changelog, "patch", message)
  end

  def do_not_publish_package
    add_cli_input "n"
  end

  def confirm_publish_package
    add_cli_input "y"
  end

  def run_publish( # rubocop:disable Metrics/ParameterLists
    args = [],
    lang:,
    failed_commands: [],
    stubbed_commands: [],
    before_command: nil,
    strip_changeset_output: true
  )
    integration_config = LANGUAGE_PUBLISH_SETUP.fetch(lang, {})
    prepare_cli_input
    integration_config[:publish_commands].each do |cmd|
      # If stubbed and failing, it won't fail because it's stubbed
      stubbed_commands << cmd unless failed_commands.include?(cmd)
    end
    stubbed_commands << /^git push/
    output =
      capture_stdout do
        in_project do
          perform_commands do
            fail_commands failed_commands do
              stub_commands stubbed_commands do
                # Run commands before the publish process
                integration_config[:before_commands]&.each(&:call)
                before_command&.call
                Mono::Cli::Wrapper.new(["publish"] + args).execute
              end
            end
          end
        end
      end
    if strip_changeset_output
      strip_changeset_output output
    else
      output
    end
  end

  def run_bootstrap(args = [])
    Mono::Cli::Wrapper.new(["bootstrap"] + args).execute
  end
  module_function :run_bootstrap

  # Strip all changeset summary output from the output string.
  # Useful when only testing version changes, and not the summary itself.
  def strip_changeset_output(output)
    new_output = []
    changesets = false
    output.lines do |line|
      # When a line doesn't start with space, it means we're not printing
      # changesets from a package anymore
      changesets = false unless line.start_with?(" ")
      next if changesets # Skip all changeset lines

      if line == "  Changesets:\n" # Changeset summary detected, skipping
        changesets = true
        next
      end
      new_output << line
    end
    new_output.join
  end
end
