require 'test/unit'

require 'damagecontrol/BuildRequestEvent'
require 'damagecontrol/SocketTrigger'
require 'damagecontrol/Hub'
require 'damagecontrol/Build'

require 'socket'

module DamageControl

	class SocketTriggerTest < Test::Unit::TestCase

		def test_fires_build_request_on_socket_accept

			build = Build.new("foo")
			
			bre = BuildRequestEvent.new(build)

			hub = Hub.new()
			@s = SocketTrigger.new(hub, build)
			@s.do_accept()
			assert_equal( bre, hub.last_message() )
			
		end
				
	end
	
end

