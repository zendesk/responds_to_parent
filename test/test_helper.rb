require 'bundler/setup'
require 'action_controller'
require 'action_dispatch/testing/test_process'
require 'prototype-rails/on_load_action_view'
require 'prototype-rails/on_load_action_controller'
require 'test/unit'

require_relative '../lib/responds_to_parent'

ROUTES = ActionDispatch::Routing::RouteSet.new
ROUTES.draw do
  match ':controller(/:action(/:id(.:format)))'
end
ROUTES.finalize!

# funky patch to get @routes working, in 'setup' did not work
module ActionController::TestCase::Behavior
  def process_with_routes(*args)
    @routes = ROUTES
    process_without_routes(*args)
  end
  alias_method_chain :process, :routes
end
