Gem::Specification.new do |s|
  s.name               = "sinatra-my-params"
  s.version            = "0.0.5"
  s.default_executable = "permit_params"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Marco Aviles"]
  s.date = %q{2021-09-19}
  s.description = %q{A simple sinatra params sanitizer}
  s.email = %q{gdmarav374@gmail.com}
  s.files = ["Rakefile", "lib/permit_params.rb", "bin/permit_params"]
  s.test_files = ["spec/permit_params_spec.rb"]
  s.homepage = %q{https://github.com/mhero/sinatra-my-params}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{permit_params!}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

