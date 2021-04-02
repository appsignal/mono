module GitHelper
  def local_changes
    `git status -s -u`.split("\n").each do |change|
      change.gsub!(/^.. /, "")
    end
  end

  def local_changes?
    local_changes.any?
  end

  def commited_files
    `git diff HEAD~1 --stat --name-only`.split("\n").sort
  end
end
