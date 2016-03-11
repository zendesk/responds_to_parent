require 'responds_to_parent/action_controller'
require 'responds_to_parent/selector_assertion'

ActionController::Base.include RespondsToParent::ActionController
[
  ActionDispatch::Assertions::SelectorAssertions,
  ActionController::TestCase
].each do |to_include|
  to_include.include RespondsToParent::SelectorAssertion
end
