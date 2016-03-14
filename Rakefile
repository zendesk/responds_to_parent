require 'bundler/setup'
require 'wwtd/tasks'
require 'bump/tasks'
require 'rake/testtask'

desc 'Test the responds_to_parent plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
  t.warning = false
end

task default: :test
