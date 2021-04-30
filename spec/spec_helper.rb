# frozen_string_literal: true

require "mono"
require "mono/cli"
require "testing"

ROOT_DIR = File.expand_path("..", __dir__)
SPEC_DIR = File.expand_path(__dir__)
Dir.glob("support/**/*.rb", :base => SPEC_DIR).sort.each do |file|
  require file
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random
  Kernel.srand config.seed

  config.include CommandHelper
  config.include StdStreamsHelper
  config.include ProjectHelper
  config.include GitHelper
  config.include ChangesetHelper

  config.before :suite do
    Testing.clear!
  end

  config.before :all do
    Testing.clear!
  end

  config.before :each do
    Testing.clear!
    clear_selected_project!
  end
end
