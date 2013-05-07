require 'appraisal'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

task :default do
  sh "bundle exec rake appraisal:install && bundle exec rake appraisal test"
end

desc 'Test the responds_to_parent plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the responds_to_parent plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'RespondsToParent'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
