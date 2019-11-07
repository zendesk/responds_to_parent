require_relative 'lib/responds_to_parent/version'

Gem::Specification.new do |s|
  s.name        = 'responds_to_parent'
  s.version     = RespondsToParent::VERSION
  s.authors     = ['Michael Grosser', 'Pierre Schambacher']
  s.homepage    = 'https://github.com/zendesk/responds_to_parent'
  s.summary     = "[Rails] Adds 'responds_to_parent' to your controller to" +
                  'respond to the parent document of your page.'            +
                  'Make Ajaxy file uploads by posting the form to a hidden' +
                  'iframe, and respond with RJS to the parent window.'

  s.files = Dir.glob('lib/**/*')

  s.add_runtime_dependency('actionpack', '>= 3.2.22', '< 5.0')

  s.add_development_dependency('prototype-rails')
  s.add_development_dependency('rake')
  s.add_development_dependency('minitest')
  s.add_development_dependency('byebug')
  s.add_development_dependency('wwtd')
  s.add_development_dependency('bump')
end
