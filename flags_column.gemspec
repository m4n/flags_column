# -*- encoding: utf-8 -*-
lib = File.expand_path("../lib", __FILE__)
$:.unshift lib unless $:.include?(lib)

require "flags_column/version"

Gem::Specification.new do |s|
  s.name        = "flags_column"
  s.version     = FlagsColumn::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Martin Andert"]
  s.email       = ["martin@mehringen.de"]
  s.homepage    = ""
  s.summary     = %q{A Rails3 gem that extends ActiveRecord to provide enhanced access to bit-flagged columns.}
  s.description = %q{A Rails3 gem that extends ActiveRecord to provide enhanced access to bit-flagged columns.}

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project = "flags_column"

  s.extra_rdoc_files = ["README.rdoc", "MIT-LICENSE"]
  s.rdoc_options = ["--charset=UTF-8"]
  s.homepage = %q{http://github.com/m4n/flags_column}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency("rails", ["~> 3.0.0"])

  s.add_development_dependency("rspec-rails", ["~> 2.5.0"])
end

