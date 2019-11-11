ruby_version = Gem::Version.new(RUBY_VERSION)

if ruby_version >= Gem::Version.new('2.6') && ActionPack.gem_version < Gem::Version.new('5.0')
  class ActionController::TestResponse < ActionDispatch::TestResponse
    def recycle!
      # HACK: to avoid MonitorMixin double-initialize error:
      @mon_mutex_owner_object_id = nil
      @mon_mutex = nil
      initialize
    end
  end
else
  puts "#{__FILE__} is no longer required"
end
