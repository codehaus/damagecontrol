require 'test/unit'

require 'damagecontrol/BuildRequestEvent'
require 'damagecontrol/SocketTrigger'
require 'damagecontrol/Hub'
require 'damagecontrol/Project'

require 'socket'

module DamageControl

	class SocketTriggerTest < Test::Unit::TestCase

		def test_fires_build_request_on_socket_accept

			project = Project.new("foo")
			
			bre = BuildRequestEvent.new(project)

			hub = Hub.new()
			@s = SocketTrigger.new(hub, project)
			@s.do_accept()
			assert_equal( bre, hub.last_message() )
			
		end
				
	end
	
end

