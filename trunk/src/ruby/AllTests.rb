require 'test/unit'
require 'damagecontrol/dependency/AllTraverserTest'
require 'damagecontrol/dependency/UpstreamDownstreamTraverserTest'

class CommandLineBuilderTest < Test::Unit::TestCase

	def setup
		@hub = Hub.new
		@b = CommandLineBuilder.new(@hub, "echo Hello Aslak!")
	end

	def test_executes_process_and_sends_build_complete_on_receive_build_request
		@b.receive_message(BuildRequestEvent.new())
		assert_equal(BuildCompleteEvent.new("Hello Aslak!\n"), @hub.last_message)
		assert_equal("Hello Aslak!\n", @hub.last_message.result)
	end
	
	def test_doesnt_do_anything_on_other_events
		@b.receive_message(nil)
		assert_equal(nil, @hub.last_message)
	end
	
end

class CommandLineBuilder
	
	def initialize(hub, command_line)
		@hub = hub
		@command_line = command_line
	end
	
	def receive_message(message)
		result = ""
		IO.popen(@command_line) {|f| result = f.gets}
		@hub.publish_message(BuildCompleteEvent.new(result)) if message.is_a? BuildRequestEvent
	end
	
end

class Hub
	attr_reader :last_message 
	
	def publish_message(message)
		@last_message=message
	end
end

class BuildRequestEvent
end

class BuildCompleteEvent
	attr_accessor :result
	
	def initialize(result)
		@result = result
	end
	
	def ==(obj)
		obj.result == result
	end
end