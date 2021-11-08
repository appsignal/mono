# frozen_string_literal: true

module PublishHelper
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

  def run_publish(args = [])
    prepare_cli_input
    Mono::Cli::Wrapper.new(["publish"] + args).execute
  end

  def run_bootstrap(args = [])
    Mono::Cli::Wrapper.new(["bootstrap"] + args).execute
  end

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
