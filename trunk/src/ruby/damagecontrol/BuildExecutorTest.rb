require 'test/unit'
require 'damagecontrol/Hub'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/HubTestHelper'

module DamageControl

  class Subscriber
    def initialize(&proc)
      @proc = proc
    end
    
    def receive_message(message)
      @proc.call(message)
    end
  end

  class BuildExecutorTest < Test::Unit::TestCase
  
    include HubTestHelper
    include FileUtils
  
    def setup
      create_hub
      @build_executor = BuildExecutor.new(hub, File.expand_path("#{damagecontrol_home}/testdata"))
      @build = Build.new("damagecontrolled", {"build_command_line" => "echo Hello world from DamageControl!"})
      @quiet_period = 10
    end
  
    def test_executes_process_and_sends_build_complete_on_build_request
      @build_executor.schedule_build(@build)
      @build_executor.process_next_scheduled_build
      assert_message_types_from_hub([BuildProgressEvent, BuildCompleteEvent])
      assert_equal("Hello world from DamageControl!", messages_from_hub[0].output.chomp.chomp(" "))
      assert_equal(BuildCompleteEvent.new(@build), messages_from_hub[1])
    end
    
    def test_failing_build_sends_build_complete_event_with_successful_flag_set_to_false
      @build = Build.new("damagecontrolled", { "build_command_line" => "bad_command"})
      @build_executor.schedule_build(@build)
      @build_executor.process_next_scheduled_build
      assert(message_from_hub[-2] instanceof BuildCompleteEvent)
      assert(message_from_hub[-1] instanceof BuildProgressEvent)
      assert(!messages_from_hub[-1].build.successful)
    end
    
    def test_succesful_ant_build
    
      @build = Build.new("damagecontrolled", { "build_command_line" => "#{ant} compile"})
      
      successful = nil
      hub.add_subscriber(Subscriber.new do |message|
        if (message.is_a?(BuildProgressEvent))
          puts message.output
          successful = true if(/BUILD SUCCESSFUL/ =~ message.output)
        end
      end)
      
      @build_executor.schedule_build(@build)
      @build_executor.process_next_scheduled_build

      assert(successful, "ant build should succeed (HINT: is ant really installed?)")
      
    end
    
    private
    
    def ant
      windows? ? "ant.bat" : "ant"
    end
  end
    
end
