require 'bundler/setup'
require 'minitest/autorun'
require 'action_controller'
require 'action_view'
require 'action_dispatch/testing/test_process'
require_relative 'prototype-rails'
require_relative '../lib/responds_to_parent'
require_relative 'ruby_2.6_patch'

ROUTES = ActionDispatch::Routing::RouteSet.new
ROUTES.draw do
  match ':controller(/:action(/:id(.:format)))', via: :get
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

class ActionController::Base
  def _routes
    ROUTES
  end
end

if ActionPack::VERSION::STRING >= '4.2.0'
  require 'rails-dom-testing'
  ActionController::TestCase.class_eval do
    include Rails::Dom::Testing::Assertions::SelectorAssertions
  end
  ActiveSupport::TestCase.test_order = :sorted
end
