require 'test/unit'
require 'pebbles/mockit'
require 'damagecontrol/publisher/IRCPublisher'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/FileUtils'
require 'rubygems'
require 'rscm'

module DamageControl

  class IRCPublisherTest < Test::Unit::TestCase
 
    include MockIt
  
    def setup
      @hub = new_mock
      @hub.__expect(:add_consumer) do |subscriber|
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
        expected = "<a href=\"http://moradi.com/public/project/cheese?dc_creation_time=19710228234500\">[cheese] BUILD SUCCESSFUL</a>"
        assert_equal(expected, message)
      }
      
      b = Build.new("cheese", {}, "http://moradi.com/public/")
      b.status = Build::SUCCESSFUL
      b.dc_creation_time = Time.utc(1971,2,28,23,45,0,0)
      evt = BuildCompleteEvent.new(b)
      @publisher.on_message(evt)
    end
        
    def test_sends_message_on_build_requested_and_started
      now = Time.new.utc
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
        assert_match(/by jtirsen .* ago/, message)
      }
      @irc_mock.__expect(:send_message_to_channel) {|message| 
        assert_match(/file.txt 3.2/, message)
      }
      @irc_mock.__expect(:send_message_to_channel) {|message| 
        assert_match(/other_file.txt 5.1/, message)
      }
      
      @publisher.send_message_on_build_request = true
      
      build = Build.new("project")
      build.dc_creation_time = Time.utc(2004, 9, 3, 15, 0, 0)
      build.changesets.add(RSCM::Change.new("file.txt", "jtirsen", "bad ass refactoring", "3.2", now))
      build.changesets.add(RSCM::Change.new("other_file.txt", "jtirsen", "bad ass refactoring", "5.1", now))
      @publisher.on_message(BuildRequestEvent.new(build))
      @publisher.on_message(BuildStartedEvent.new(build))
    end

  end
end
