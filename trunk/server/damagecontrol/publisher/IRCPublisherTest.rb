require 'test/unit'
require 'pebbles/mockit'
require 'damagecontrol/publisher/IRCPublisher'
require 'damagecontrol/scm/Changes'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/FileUtils'

module DamageControl

  class IRCPublisherTest < Test::Unit::TestCase
  
    include MockIt

    def setup
      @hub = new_mock
      @hub.__expect(:add_subscriber) do |subscriber|
        assert(subscriber.is_a?(IRCPublisher))
      end
      @publisher = IRCPublisher.new(@hub, "server", "channel", "short_html_build_result.erb")
      @irc_mock = new_mock
      @publisher.irc = @irc_mock
    end
    
    def setup_irc_connected
      @irc_mock.__setup(:connected?) { true }
      @irc_mock.__setup(:in_channel?) { true }
    end
    
    def test_sends_message_on_build_complete
      setup_irc_connected
      @irc_mock.__expect(:send_message_to_channel) {|message|
        expected = "<a href=\"http://moradi.com/public/project?action=build_details&project_name=cheese&timestamp=19710228234500\">[cheese] BUILD SUCCESSFUL</a>"
        assert_equal(expected, message)
      }
      
      b = Build.new("cheese")
      b.status = Build::SUCCESSFUL
      b.url = "http://moradi.com/public/project?action=build_details&project_name=cheese&timestamp=19710228234500"
      b.timestamp = Time.utc(1971,2,28,23,45,0,0)
      evt = BuildCompleteEvent.new(b)
      @publisher.on_message(evt)
    end
        
    def test_sends_message_on_changesets  
      now = Time.new.utc
      setup_irc_connected 
      @irc_mock.__expect(:send_message_to_channel) {|message| 
        assert_equal("[my_project] CHECKOUT REQUESTED", message)
      }
      @irc_mock.__expect(:send_message_to_channel) {|message| 
        assert_equal("[my_project] (by jtirsen 0 seconds ago) : bad ass refactoring", message)
      }
      @irc_mock.__expect(:send_message_to_channel) {|message| 
        assert_equal("[my_project] some/file.txt 3.2", message)
      }
      @irc_mock.__expect(:send_message_to_channel) {|message| 
        assert_equal("[my_project] other_file.txt 5.1", message)
      }
      @irc_mock.__expect(:send_message_to_channel) {|message| 
        assert_equal("[my_project] CHECKOUT COMPLETE", message)
      }
      @irc_mock.__expect(:send_message_to_channel) {|message| 
        assert_equal("[my_other_project] First checkout. Last change was at #{now}", message)
      }
            
      @irc_mock.__expect(:send_message_to_channel) {|message| 
        assert_equal("[my_other_project] CHECKOUT COMPLETE", message)
      }

      @publisher.send_message_on_build_request = true

      changesets = ChangeSets.new
      changesets.add(Change.new("some/file.txt", "jtirsen", "bad ass refactoring", "3.2", now))
      changesets.add(Change.new("other_file.txt", "jtirsen", "bad ass refactoring", "5.1", now))
      @publisher.on_message(DoCheckoutEvent.new("my_project", false))
      @publisher.on_message(CheckedOutEvent.new("my_project", changesets, false))
      @publisher.on_message(CheckedOutEvent.new("my_other_project", now, false))
    end

  end
end
