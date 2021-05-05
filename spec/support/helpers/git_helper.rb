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

  def commited_files
    lines = run_command("git diff HEAD~1 --stat --name-only")
    lines.split("\n").sort
  end

  def commit_changes(message)
    run_command "git add ."
    run_command %(git commit -m " #{message}")
  end
end
