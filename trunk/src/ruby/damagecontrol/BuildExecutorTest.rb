require 'test/unit'
require 'mock_with_returns'
require 'damagecontrol/Hub'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/HubTestHelper'

module DamageControl

  class BuilderExecutorTest < Test::Unit::TestCase
  
    include HubTestHelper
    include FileUtils
  
    def setup
      create_hub
      @build_executor = BuildExecutor.new(hub, File.expand_path("#{damagecontrol_home}/testdata"))
      @build = Build.new("damagecontrolled")
      @build.build_command_line = "echo Hello world from DamageControl!"
    end
  
    def test_executes_process_and_sends_build_complete_on_build_request
      hub.publish_message(BuildRequestEvent.new(@build))
      @build_executor.force_tick
      assert_message_types([BuildRequestEvent, BuildProgressEvent, BuildCompleteEvent])
      assert_equal(BuildProgressEvent.new(@build, "Hello world from DamageControl!\n"), messages_from_hub[1])
      assert_equal("Hello world from DamageControl!\n", messages_from_hub[1].output)
      assert_equal(BuildCompleteEvent.new(@build), messages_from_hub[2])
    end
    
    def test_doesnt_do_anything_on_other_events
      @build_executor.receive_message(nil)
      assert_equal(nil, hub.last_message)
    end
    
    class Subscriber
      def initialize(&proc)
        @proc = proc
      end
      
      def receive_message(message)
        @proc.call(message)
      end
    end
    
    def test_build_failed
    
      build = Build.new( \
        "DamageControlled", \
        ":local:/foo/bar:zap", \
        "#{ant} compile")
      
      successful = nil
      @hub.add_subscriber(Subscriber.new do |message|
        if (message.is_a?(BuildProgressEvent))
          puts message.output
          successful = true if(/BUILD SUCCESSFUL/ =~ message.output)
        end
      end)
      
      @build_executor.process_message(BuildRequestEvent.new(build))
      @build_executor.force_tick

      assert(successful, "Ant build should succeed")
      
    end
    
    private
    
    def ant
      windows? ? "ant.bat" : "ant"
    end
  end
    
end
