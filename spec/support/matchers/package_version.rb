# frozen_string_literal: true

RSpec::Matchers.define :have_ruby_version do |version|
  match do |actual|
    expect(actual).to include(%(VERSION = "#{version}"))
  end
end
