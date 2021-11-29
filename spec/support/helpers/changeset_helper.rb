# frozen_string_literal: true

module ChangesetHelper
  def add_changeset(bump, message: nil)
    @changeset_count ||= 0
    @changeset_count += 1
    FileUtils.mkdir_p(".changesets")
    path = ".changesets/#{@changeset_count}_#{bump}.md"
    unless bump == :none
      metadata = <<~METADATA
        ---
        bump: #{bump}
        ---

      METADATA
    end
    message ||= "This is a #{bump} changeset bump."
    File.open(path, "w+") do |file|
      file.write("#{metadata}#{message}")
    end
    commit_changeset("Changeset #{@changeset_count} #{bump}")
    path
  end

  def commit_changeset(message = "No message")
    @commit_count ||= 0
    @commit_count += 1
    commit_changes "Commit #{@commit_count}: #{message}"
  end

  def current_package_changeset_files
    Dir.glob(".changesets/*.md")
  end
end
