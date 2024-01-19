# frozen_string_literal: true

RSpec::Matchers.define :have_publish_summary do |projects|
  match do |actual|
    matchers = []
    Array(projects).each do |project_name, options|
      matchers <<
        if options == :no_publish
          "- #{project_name}: (Will not publish)"
        else
          <<~MATCHER
            - #{project_name}:
              Current version: #{options[:old]}
              Next version:    #{options[:new]} (#{options[:bump]})
          MATCHER
        end
    end
    expect(actual).to include(<<~OUTPUT), actual
      The following packages will be published (or not):
      #{matchers.join}
    OUTPUT
  end
end

RSpec::Matchers.define :have_update_summary do |projects|
  match do |actual|
    matchers = []
    Array(projects).each do |project_name, options|
      matchers <<
        if options != :no_publish
          <<~MATCHER
            - #{project_name}:
              Current version: #{options[:old]}
              Next version:    #{options[:new]} (#{options[:bump]})
          MATCHER
        end
    end
    expect(actual).to include(<<~OUTPUT), actual
      # Updating package versions
      #{matchers.compact.join}
    OUTPUT
  end
end

RSpec::Matchers.define :has_publish_and_update_summary do |projects|
  match do |actual|
    expect(actual).to have_publish_summary(projects)
    expect(actual).to have_update_summary(projects)
  end
end
