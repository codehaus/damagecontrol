require 'test/unit'
require 'pebbles/mockit'
require 'damagecontrol/publisher/IRCPublisher'
require 'damagecontrol/scm/Changes'
require 'damagecontrol/core/Hub'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/FileUtils'

module DamageControl

  class DcServerStub
    def dc_url
      "http://moradi.com/"
    end
  end

  class IRCPublisherTest < Test::Unit::TestCase
  
    def setup
      @publisher = IRCPublisher.new(Hub.new, DcServerStub.new, "server", "channel", "short_html_build_result.erb")
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
        assert_equal(message, "<a href=\"http://moradi.com/public/project?action=build_details&project_name=cheese&timestamp=19710228234500\">[cheese] BUILD SUCCESSFUL</a>")}
      
      b = Build.new("cheese")
      b.status = Build::SUCCESSFUL
      b.timestamp = Time.utc(1971,2,28,23,45,0,0)
      evt = BuildCompleteEvent.new(b)
      @publisher.enq_message(evt)
      @publisher.process_messages
    end
    
    def test_formats_changeset_according_to_changeset
      changeset = 
        [
          Change.new("file1.txt", "jtirsen", "change1"),
          Change.new("file2.txt", "jtirsen", "change1"),
          Change.new("file3.txt", "jtirsen", "change2"),
          Change.new("file4.txt", "rinkrank", "change2"),
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
      build.modification_set = [Change.new("file.txt", "jtirsen")]
      @publisher.enq_message(BuildRequestEvent.new(build))
      @publisher.enq_message(BuildStartedEvent.new(build))
      @publisher.process_messages
    end

  end
end
