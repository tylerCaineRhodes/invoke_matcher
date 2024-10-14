# frozen_string_literal: true

require_relative "lib/invoke_matcher/version"

Gem::Specification.new do |spec|
  spec.name = "invoke_matcher"
  spec.version = InvokeMatcher::VERSION
  spec.authors = ["Tyler Rhodes"]
  spec.email = ["rhodetyl000@gmail.com"]

  spec.summary = "RSpec matcher for testing method invocations"
  spec.homepage = "https://github.com/tylerCaineRhodes/invoke_matcher"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/tylerCaineRhodes/invoke_matcher"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.files = Dir["lib/**/*.rb"]
  File.basename(__FILE__)
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
