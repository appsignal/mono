require File.expand_path("../lib/appsignal/version", __FILE__)

Gem::Specification.new do |gem| # rubocop:disable Metrics/BlockLength
  gem.name          = "ruby_single_project"
  gem.authors       = ["Tom de Bruijn" ]
  gem.email         = ["support@appsignal.com"]
  gem.description   = "Dummy gem description"
  gem.summary       = "Dummy gem summary"
  gem.homepage      = "https://github.com/appsignal/ruby_single_project"
  gem.license       = "MIT"
  gem.files         = `git ls-files`.split($\).reject { |f| f.start_with?(".changesets/") }
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = %w[lib]
  gem.version       = Appsignal::VERSION
end
