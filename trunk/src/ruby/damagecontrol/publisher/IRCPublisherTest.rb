require 'test/unit'
require 'mockit'
require 'damagecontrol/publisher/IRCPublisher'
require 'damagecontrol/Hub'
require 'damagecontrol/Build'
require 'damagecontrol/FileUtils'
require 'damagecontrol/template/MockTemplate'

module DamageControl

  class IRCPublisherTest < Test::Unit::TestCase
  
    def setup
      @mock_template = MockTemplate.new
      @publisher = IRCPublisher.new(Hub.new, "server", "channel", @mock_template)
      @irc_mock = MockIt::Mock.new
      @publisher.irc = @irc_mock
    end
    
    def setup_irc_connected
      @irc_mock.__setup(:connected?) { true }
      @irc_mock.__setup(:in_channel?) { true }
    end
    
    def teardown
      @irc_mock.__verify
    end
    
    def test_sends_message_on_build_complete
      setup_irc_connected
      @irc_mock.__expect(:send_message_to_channel) {|message| 
        assert_equal(message, @mock_template.generate(nil))}
      
      evt = BuildCompleteEvent.new(Build.new("project_name"))
      @publisher.enq_message(evt)
      @publisher.process_messages
      
      assert(@publisher.consumed_message?(evt))
    end
    
    def test_sends_message_on_build_requested_and_started
      setup_irc_connected
      @irc_mock.__expect(:send_message_to_channel) {|message| 
        assert_match(/REQUESTED/, message)
        assert_match(/project/, message)
      }
      @irc_mock.__expect(:send_message_to_channel) {|message| 
        assert_match(/jtirsen/, message)
        assert_match(/STARTED/, message)
        assert_match(/project/, message)
      }
      
      @publisher.send_message_on_build_request = true
      
      build = Build.new("project")
      mod = Modification.new
      mod.developer = "jtirsen"
      mod.path = "this/is/a/file.txt"
      build.modification_set = [mod]
      @publisher.enq_message(BuildRequestEvent.new(build))
      @publisher.enq_message(BuildStartedEvent.new(build))
      @publisher.process_messages
    end

  end
end
