require 'test/unit'
require 'pebbles/mockit'

require 'fileutils'

require 'damagecontrol/core/Build'
require 'damagecontrol/core/Hub'
require 'damagecontrol/core/BuildExecutor'
require 'damagecontrol/util/HubTestHelper'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/core/BuildHistoryRepository'
require 'damagecontrol/core/ProjectDirectories'

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
      @basedir = new_temp_dir("BuildExecutorTest")
      @build_executor = BuildExecutor.new(hub, BuildHistoryRepository.new(hub), ProjectDirectories.new(@basedir))
      @build = Build.new("damagecontrolled", Time.now, {"build_command_line" => "echo Hello world from DamageControl!"})
      @quiet_period = 10
    end
    
    def teardown
      rm_rf(@basedir)
    end
  
    def test_when_build_scheduled_executes_sends_start_process_and_complete
      @build_executor.schedule_build(@build)
      @build_executor.process_next_scheduled_build
      assert_message_types_from_hub([BuildStartedEvent, BuildProgressEvent, BuildCompleteEvent])
      assert_equal("Hello world from DamageControl!", messages_from_hub[1].output.chomp.chomp(" "))
      assert_equal(BuildCompleteEvent.new(@build), messages_from_hub[2])
    end
    
    def test_failing_build_sends_build_complete_event_with_successful_flag_set_to_false
      @build = Build.new("damagecontrolled", Time.now, { "build_command_line" => "bad_command"})
      @build_executor.schedule_build(@build)
      @build_executor.process_next_scheduled_build
      # what happens for bad_command is different on windows and linux
      # windows? returns false on cygwin, so this doesn't work
#      if(windows?)
#        assert(messages_from_hub[-2].is_a?(BuildStartedEvent))
#      else
#        assert(messages_from_hub[-2].is_a?(BuildProgressEvent))
#      end
      assert(messages_from_hub[-1].is_a?(BuildCompleteEvent))
      assert_equal(Build::FAILED, messages_from_hub[-1].build.status)
    end
    
    def test_checks_out_and_determines_changes_before_building      
      checkoutdir = "#{@basedir}/damagecontrolled/checkout/damagecontrolled"
      
      mock_build_history = MockIt::Mock.new
      mock_build_history.__expect(:last_succesful_build) { |project_name|
        assert_equal("damagecontrolled", project_name)
        b = Build.new("damagecontrolled")
        b.timestamp = Time.utc(2004, 04, 02, 12, 00, 00)
        b
      }
      mock_scm = MockIt::Mock.new
      mock_scm.__expect(:changes) { |scm_spec, dir, time_before, time_after|
        assert_equal("scm_spec", scm_spec)
        assert_equal(checkoutdir, dir)
        assert_equal(Time.utc(2004, 04, 02, 12, 00, 00), time_before)
        assert_equal(Time.utc(2004, 04, 02, 13, 00, 00), time_after)
      }
      mock_scm.__expect(:checkout) { |scm_spec, dir|
        assert_equal("scm_spec", scm_spec)
        assert_equal(checkoutdir, dir)
      }
      
      FileUtils.mkdir_p(checkoutdir)
      
      @build_executor = BuildExecutor.new(hub, mock_build_history, ProjectDirectories.new(@basedir), mock_scm)
      @build = Build.new("damagecontrolled", Time.now,
        { "scm_spec" => "scm_spec", "build_command_line" => "echo hello world"})
      @build.timestamp = Time.utc(2004, 04, 02, 13, 00, 00)

      @build_executor.schedule_build(@build)
      @build_executor.process_next_scheduled_build
      
      assert_equal(nil, @build.error_message)
      assert_equal(Build::SUCCESSFUL, @build.status)
      
      mock_build_history.__verify
      mock_scm.__verify
    end
    
    private
    
    def ant
      windows? ? "ant.bat" : "ant"
    end
  end
  
end