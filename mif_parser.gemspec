
require_relative "lib/mif_parser/version"

Gem::Specification.new do |spec|
  spec.name        = "mif_parser"
  spec.version     = MifParser::VERSION
  spec.authors     = ["4-dash"]
  spec.summary     = "Adobe FrameMaker MIF parser"
  spec.description = "Parses FrameMaker MIF files into structured Ruby objects."
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.1.0"

  spec.files = Dir["lib/**/*"]
  spec.require_paths = ["lib"]
end