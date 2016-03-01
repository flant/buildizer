require File.expand_path("../lib/thepackager/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name = 'thepackager'
  spec.version = Thepackager::VERSION

  spec.summary = ''
  spec.description = spec.summary
  spec.homepage = 'https://github.com/flant/thepackager'

  spec.authors = ['']
  spec.email = ''
  spec.license = ''

  spec.files = Dir['lib/**/*', 'README*', 'LICENSE*']
  spec.executables = ['thepackager']

  spec.add_dependency 'thor', '>= 0.19.1', '< 1.0'
  spec.add_development_dependency 'bundler', '>= 1.1', '< 2.0'
  spec.add_development_dependency 'pry', '>= 0.10.3', '< 1.0'
end
