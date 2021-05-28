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

  def expect_changelog_to_include_package_bump(changelog, package, version)
    url = "https://github.com/appsignal/#{current_project}"
    message = "Update #{package} dependency to #{version}"
    expect(changelog)
      .to match(%r{- \[[a-z0-9]{7}\]\(#{url}/commit/[a-z0-9]{40}\) patch - #{message}})
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
end