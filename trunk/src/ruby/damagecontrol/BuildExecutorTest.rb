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
  
    def test_when_build_scheduled_executes_sends_start_process_and_complete
      @build_executor.schedule_build(@build)
      @build_executor.process_next_scheduled_build
      assert_message_types_from_hub([BuildStartedEvent, BuildProgressEvent, BuildCompleteEvent])
      assert_equal("Hello world from DamageControl!", messages_from_hub[1].output.chomp.chomp(" "))
      assert_equal(BuildCompleteEvent.new(@build), messages_from_hub[2])
    end
    
    def test_failing_build_sends_build_complete_event_with_successful_flag_set_to_false
      @build = Build.new("damagecontrolled", { "build_command_line" => "bad_command"})
      @build_executor.schedule_build(@build)
      @build_executor.process_next_scheduled_build
      # what happens for bad_command is different on windows and linux
      if(windows?)
        assert(messages_from_hub[-2].is_a?(BuildProgressEvent))
      else
        assert(messages_from_hub[-2].is_a?(BuildStartedEvent))
      end
      assert(messages_from_hub[-1].is_a?(BuildCompleteEvent))
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
