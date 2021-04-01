require_relative 'lib/deletic/version'

Gem::Specification.new do |spec|
  spec.name          = "deletic"
  spec.version       = Deletic::VERSION
  spec.authors       = ["Kharisma Putra"]
  spec.email         = ["ks.dwiputra@gmail.com"]

  spec.summary       = %q{ActiveRecord soft-deletes done right}
  spec.description   = %q{Allows marking ActiveRecord objects as soft_deleted, and provides scopes for filtering.}
  spec.homepage      = "https://github.com/ksdputra/deletic"
  spec.license       = "MIT"

  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 5.2", "< 7"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "database_cleaner", "~> 1.5"
  spec.add_development_dependency "with_model", "~> 2.0"
  spec.add_development_dependency "sqlite3"
end
