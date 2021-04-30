# frozen_string_literal: true

module ChangesetHelper
  def add_changeset(bump)
    @changeset_count ||= 0
    @changeset_count += 1
    FileUtils.mkdir_p(".changesets")
    File.open(".changesets/#{@changeset_count}_#{bump}.md", "w+") do |file|
      file.write(<<~CHANGESET)
        ---
        bump: #{bump}
        ---

        This is a #{bump} changeset bump.
      CHANGESET
    end
    commit_changeset("Changeset #{@changeset_count} #{bump}")
  end

  def commit_changeset(message = "No message")
    @commit_count ||= 0
    @commit_count += 1
    `git add . && git commit -m "Commit #{@commit_count}: #{message}"`
  end

  def current_package_changeset_files
    Dir.glob(".changesets/*.md")
  end
end
