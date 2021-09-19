require "rake/testtask"
require "rspec/core/rake_task"

Rake::TestTask.new do |t|
  t.libs << "test"
end

begin
  RSpec::Core::RakeTask.new(:spec)

  task :default => :spec
rescue LoadError
end
