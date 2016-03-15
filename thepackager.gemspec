require File.expand_path("../lib/thepackager/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name = "thepackager"
  spec.version = Thepackager::VERSION
  spec.authors = ["flant"]
  spec.email = "256@flant.com"

  spec.summary = "Packaging tool"
  spec.description = "#{spec.summary}."
  spec.license = "MIT"
  spec.homepage = "https://github.com/flant/thepackager"

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables = ["thepackager"]

  spec.required_ruby_version = ">= 2.2.1"

  spec.add_dependency "thor", ">= 0.19.1", "< 1.0"
  spec.add_dependency "net_status", ">= 0.0.1", "< 1.0"
  spec.add_dependency "mixlib-shellout", ">= 2.2.6", "< 3.0"
  spec.add_dependency "travis", "~> 1.8", ">= 1.8.2"
  spec.add_dependency "package_cloud", ">= 0.2", "< 1.0"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.4", ">= 3.4.0"
  spec.add_development_dependency "pry", ">= 0.10.3", "< 1.0"
  spec.add_development_dependency 'pry-stack_explorer', '>= 0.4.9.2', '< 1.0'
end
