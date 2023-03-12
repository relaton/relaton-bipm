require_relative "lib/relaton_bipm/version"

Gem::Specification.new do |spec| # rubocop:disable Metrics/BlockLength
  spec.name          = "relaton-bipm"
  spec.version       = RelatonBipm::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = "RelatonBipm: retrieve BIPM Standards for "\
                       "bibliographic use using the BibliographicItem model"
  spec.description   = "RelatonBipm: retrieve BIPM Standards for "\
                       "bibliographic use using the BibliographicItem model"
  spec.homepage      = "https://github.com/relaton/relaton-bipm"
  spec.license       = "BSD-2-Clause"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/relaton/relaton-bipm"
  # spec.metadata["changelog_uri"] = "Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added
  # into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "equivalent-xml", "~> 0.6"

  spec.add_dependency "faraday", "~> 1.0"
  spec.add_dependency "mechanize", "~> 2.8.0"
  spec.add_dependency "relaton-bib", "~> 1.14.0"
  spec.add_dependency "relaton-index", "~> 0.1.0"
  spec.add_dependency "rubyzip", "~> 2.3.0"
  spec.add_dependency "serrano", "~> 1.0"
end
