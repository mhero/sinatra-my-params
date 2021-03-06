# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name               = 'sinatra-my-params'
  s.version            = '0.0.10'
  s.default_executable = 'permit_params'

  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.authors = ['Marco Aviles']
  s.date = '2021-09-19'
  s.description = 'A simple params sanitizer (originally created for sinatra)'
  s.email = 'gdmarav374@gmail.com'
  s.files = ['Rakefile', 'lib/permit_params.rb', 'bin/permit_params']
  s.test_files = ['spec/permit_params_spec.rb', 'spec/permit_params_shape_spec.rb']
  s.homepage = 'https://github.com/mhero/sinatra-my-params'
  s.require_paths = ['lib']
  s.rubygems_version = '1.6.2'
  s.summary = 'permit_params!'

  if s.respond_to? :specification_version
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0')
    end
  end
end
