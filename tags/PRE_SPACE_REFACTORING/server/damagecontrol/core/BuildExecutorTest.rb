require 'test/unit'
require 'pebbles/mockit'

require 'fileutils'

require 'damagecontrol/core/Build'
require 'damagecontrol/core/Hub'
require 'damagecontrol/core/BuildExecutor'
require 'damagecontrol/util/HubTestHelper'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/core/BuildHistoryRepository'
require 'damagecontrol/core/ProjectConfigRepository'
require 'damagecontrol/core/ProjectDirectories'
require 'damagecontrol/scm/NoSCM'

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
      mkdir_p(@basedir)
      @build = Build.new("damagecontrolled", Time.now, {
        "build_command_line" => "echo Hello world from DamageControl!"
        })
      @build.scm = NoSCM.new("checkout_dir" => @basedir)
      @quiet_period = 10
    end
    
    def teardown
      #rm_rf(@basedir)
    end
    
    def wait_for(timeout=5, &proc)
      0.upto(timeout) do
        return if proc.call
        sleep 1
      end
    end
    
    def test_can_kill_a_running_build
      @build.config["build_command_line"] = "cat"
      @build_executor = BuildExecutor.new(hub, BuildHistoryRepository.new(hub))
      @build_executor.schedule_build(@build)
      t = Thread.new {
        @build_executor.process_next_scheduled_build
      }
      wait_for { @build_executor.build_process_executing? }
      assert(@build_executor.build_process_executing?)
      @build_executor.kill_build_process
      assert(!@build_executor.build_process_executing?)
      t.join
      assert_message_types_from_hub([BuildStartedEvent, BuildProgressEvent, BuildProgressEvent, BuildCompleteEvent])
      assert_equal(Build::KILLED, messages_from_hub[-1].build.status)
    end
  
    def test_when_build_scheduled_executes_sends_start_process_and_complete
      mock_scm = MockIt::Mock.new
      mock_scm.__expect(:working_dir) { "." }
      mock_scm.__expect(:checkout) {}
      mock_scm.__expect(:working_dir) { "." }
      @build.scm = mock_scm

      @build_executor = BuildExecutor.new(hub, BuildHistoryRepository.new(hub))

      @build_executor.schedule_build(@build)
      @build_executor.process_next_scheduled_build
      assert_message_types_from_hub([BuildStartedEvent, BuildProgressEvent, BuildProgressEvent, BuildCompleteEvent])
      assert_equal("echo Hello world from DamageControl!", messages_from_hub[1].output.chomp.chomp(" "))
      assert_equal("Hello world from DamageControl!", messages_from_hub[2].output.chomp.chomp(" "))
      assert_equal(BuildCompleteEvent.new(@build), messages_from_hub[3])

      mock_scm.__verify
    end
    
    def test_failing_build_sends_build_complete_event_with_successful_flag_set_to_false
      mock_scm = MockIt::Mock.new
      mock_scm.__expect(:working_dir) { "." }
      mock_scm.__expect(:checkout) {}
      mock_scm.__expect(:working_dir) { "." }
      @build_executor = BuildExecutor.new(hub, BuildHistoryRepository.new(hub))

      @build = Build.new("damagecontrolled", Time.now, { "build_command_line" => "bad_command"})
      @build.scm = mock_scm
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

      mock_scm.__verify
    end
    
    def test_checks_out_and_determines_changeset_before_building      
      checkoutdir = "#{@basedir}/damagecontrolled/checkout/damagecontrolled"
      last_build_time = Time.utc(2004, 04, 02, 12, 00, 00)
      current_build_time = Time.utc(2004, 04, 02, 13, 00, 00)
      
      mock_build_history = MockIt::Mock.new
      mock_build_history.__expect(:last_successful_build) { |project_name|
        assert_equal("damagecontrolled", project_name)
        b = Build.new("damagecontrolled")
        b.timestamp = last_build_time
        b
      }
      mock_scm = MockIt::Mock.new
      mock_scm.__setup(:working_dir) { checkoutdir }
      mock_scm.__expect(:changesets) {|from_time, to_time|
        assert_equal(last_build_time, from_time)
        assert_equal(current_build_time, to_time)
      }
      mock_scm.__expect(:checkout) {}
      
      FileUtils.mkdir_p(checkoutdir)
      
      @build_executor = BuildExecutor.new(hub, mock_build_history)
      @build = Build.new("damagecontrolled", Time.now,
        { "build_command_line" => "echo hello world"})
      @build.scm = mock_scm
      @build.timestamp = current_build_time

      @build_executor.schedule_build(@build)
      @build_executor.process_next_scheduled_build
      
      assert_equal(nil, @build.error_message)
      assert_equal(Build::SUCCESSFUL, @build.status)
      
      mock_scm.__verify
      mock_build_history.__verify
    end
    
    def ant
      windows? ? "ant.bat" : "ant"
    end
  end
end