require 'responds_to_parent/action_controller'
require 'responds_to_parent/selector_assertion'

ActionController::Base.include RespondsToParent::ActionController

where_to_include = [ActionController::TestCase]
if defined?(ActionDispatch::Assertions::SelectorAssertions)
  where_to_include << ActionDispatch::Assertions::SelectorAssertions
else
  where_to_include << Rails::Dom::Testing::Assertions::SelectorAssertions
end
where_to_include.each do |to_include|
  to_include.include RespondsToParent::SelectorAssertion
end
