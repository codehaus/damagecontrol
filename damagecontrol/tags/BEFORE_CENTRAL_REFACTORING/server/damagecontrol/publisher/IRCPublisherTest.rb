require 'test/unit'
require 'pebbles/mockit'
require 'damagecontrol/publisher/IRCPublisher'
require 'damagecontrol/core/Hub'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/template/ShortTextTemplate'

module DamageControl

  class IRCPublisherTest < Test::Unit::TestCase
  
    def setup
      @publisher = IRCPublisher.new(Hub.new, "server", "channel", ShortTextTemplate.new)
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
        assert_equal(message, "[project_name] BUILD SUCCESSFUL ")}
      
      b = Build.new("project_name")
      b.status = Build::SUCCESSFUL
      evt = BuildCompleteEvent.new(b)
      @publisher.enq_message(evt)
      @publisher.process_messages
    end
    
    def test_formats_changeset_according_to_changeset
      changeset = 
        [
          Modification.new("file1.txt", "jtirsen", "change1"),
          Modification.new("file2.txt", "jtirsen", "change1"),
          Modification.new("file3.txt", "jtirsen", "change2"),
          Modification.new("file4.txt", "rinkrank", "change2"),
        ]
      expexted_format =
      [
        '"change1" by jtirsen: file1.txt, file2.txt',
        '"change2" by jtirsen: file3.txt',
        '"change2" by rinkrank: file4.txt',
      ]
      assert_equal(expexted_format, @publisher.format_changeset(changeset))
    end
    
    def test_sends_message_on_build_requested_and_started
      setup_irc_connected 
      @irc_mock.__expect(:send_message_to_channel) {|message| 
        assert_match(/REQUESTED/, message)
        assert_match(/project/, message)
      }
      @irc_mock.__expect(:send_message_to_channel) {|message| 
        assert_match(/STARTED/, message)
        assert_match(/project/, message)
      }
      @irc_mock.__expect(:send_message_to_channel) {|message| 
        assert_match(/jtirsen/, message)
        assert_match(/file\.txt/, message)
      }
      
      @publisher.send_message_on_build_request = true
      
      build = Build.new("project")
      build.modification_set = [Modification.new("file.txt", "jtirsen")]
      @publisher.enq_message(BuildRequestEvent.new(build))
      @publisher.enq_message(BuildStartedEvent.new(build))
      @publisher.process_messages
    end

  end
end
