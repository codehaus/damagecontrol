require 'test/unit'

require 'damagecontrol/BuildRequestEvent'
require 'damagecontrol/SocketTrigger'
require 'damagecontrol/Hub'
require 'damagecontrol/Build'

require 'socket'

module DamageControl

	class SocketTriggerTest < Test::Unit::TestCase

		def test_fires_build_request_on_socket_accept

			hub = Hub.new()
			@s = SocketTrigger.new(hub)
			@s.do_accept("foo")

			evt = SocketRequestEvent.new("foo")
			assert_equal( evt, hub.last_message() )
			
		end
				
	end
	
end

