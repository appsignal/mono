# frozen_string_literal: true

module ChangesetHelper
  def add_changeset(bump, type: :add, message: nil, filename: nil)
    @changeset_count ||= 0
    @changeset_count += 1
    FileUtils.mkdir_p(".changesets")
    filename ||= "#{@changeset_count}_#{bump}"
    path = ".changesets/#{filename}.md"
    unless bump == :none
      metadata = <<~METADATA
        ---
        bump: #{bump}
        type: #{type}
        ---

      METADATA
    end
    message ||= "This is a #{bump} changeset bump."
    File.write(path, "#{metadata}#{message}")
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
