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
      @build = Build.new("damagecontrolled", {"build_command_line" => "echo Hello world from DamageControl!"})
      @quiet_period = 10
    end
  
    def test_executes_process_and_sends_build_complete_on_build_request
      hub.publish_message(BuildRequestEvent.new(@build))
      @build_executor.force_tick
      assert_message_types_from_hub([BuildRequestEvent, BuildProgressEvent, BuildCompleteEvent])
      assert_equal("Hello world from DamageControl!", messages_from_hub[1].output.chomp.chomp(" "))
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

    def build_request_at_time(time)
      build = Build.new("project", { "quiet_period" => "#{@quiet_period}" })
      build.timestamp = 0
      hub.publish_message(BuildRequestEvent.new(build))
    end

    
    def test_waits_quiet_period_after_last_build_request_before_building
      def @build_executor.checkout
        # stub it
      end
      def @build_executor.execute
        # stub it
      end
      @build_executor.clock = FakeClock.new

      @build_executor.clock.change_time(0)
      build_request_at_time(0)
      assert(!@build_executor.quiet_period_elapsed, "quiet period should not have elapsed yet")
      @build_executor.force_tick
      assert_message_types_from_hub([BuildRequestEvent])
      
      @build_executor.clock.advance(@quiet_period)
      assert(@build_executor.quiet_period_elapsed)
      @build_executor.force_tick
      assert_message_types_from_hub([BuildRequestEvent, BuildCompleteEvent])
    end
    
    def test_failing_build_sends_build_complete_event_with_successful_flag_set_to_false
      build = Build.new("damagecontrolled", { "build_command_line" => "bad_command"})
      hub.publish_message(BuildRequestEvent.new(build))
      @build_executor.force_tick
      assert_message_types_from_hub([BuildRequestEvent, BuildProgressEvent, BuildProgressEvent, BuildCompleteEvent])
      assert(!messages_from_hub[3].build.successful)
    end
    
    def test_succesful_ant_build
    
      build = Build.new("damagecontrolled", { "build_command_line" => "#{ant} compile"})
      
      successful = nil
      hub.add_subscriber(Subscriber.new do |message|
        if (message.is_a?(BuildProgressEvent))
          puts message.output
          successful = true if(/BUILD SUCCESSFUL/ =~ message.output)
        end
      end)
      
      @build_executor.receive_message(BuildRequestEvent.new(build))
      @build_executor.force_tick

      assert(successful, "ant build should succeed (HINT: is ant really installed?)")
      
    end
    
    private
    
    def ant
      windows? ? "ant.bat" : "ant"
    end
  end
    
end
