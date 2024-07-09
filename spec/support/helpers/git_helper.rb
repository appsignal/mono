module GitHelper
  def local_changes
    lines = run_command("git status -s -u")
    lines.split("\n").each do |change|
      change.gsub!(/^.. /, "")
    end
  end

  def local_changes?
    local_changes.any?
  end

  def commit_sha
    `git rev-parse HEAD`.chomp
  end

  def commit_count
    run_command "git rev-list --count HEAD"
  end

  def commited_files
    lines = run_command("git diff HEAD~1 --stat --name-only")
    lines.split("\n").sort
  end

  def git_init_directory
    run_command "git init ."
  end

  def commit_changes(message)
    run_command "git add -A"
    run_command %(git commit -m "#{message}")
  end

  def tag_changelog_contents(tag)
    contents = `git show --format=oneline --no-color --no-patch #{tag}`
    contents.lines[2..-2].join.strip
  end

  def tmp_changelog_file_for(project)
    "tmp/#{project}_changesets.txt"
  end

  def version_tag_command(tag, file = tmp_changelog_file_for(current_project))
    "git tag #{tag} --annotate --cleanup=verbatim --file #{file}"
  end
end
