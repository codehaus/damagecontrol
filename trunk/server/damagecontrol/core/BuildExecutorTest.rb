require 'test/unit'
require 'pebbles/mockit'

require 'fileutils'

require 'damagecontrol/core/Build'
require 'damagecontrol/core/Hub'
require 'damagecontrol/core/BuildExecutor'
require 'damagecontrol/core/BuildHistoryRepository'
require 'damagecontrol/core/ProjectConfigRepository'
require 'damagecontrol/core/ProjectDirectories'
require 'damagecontrol/scm/NoSCM'
require 'damagecontrol/util/FileUtils'

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
  
    include FileUtils
  
    def setup
      @basedir = new_temp_dir("BuildExecutorTest")
      @build = Build.new("damagecontrolled", Time.now, {
        "build_command_line" => "echo Hello world from DamageControl!"
        })
    end
    
    def wait_for(timeout=5, &proc) 
      0.upto(timeout) do 
        return if proc.call 
        sleep 1 
      end 
    end 
     
    def test_can_kill_a_running_build 
      # this blocks forever
      @build.config["build_command_line"] = "cat"
      @build.scm = NoSCM.new({"checkout_dir" => "."})

      mock_hub = MockIt::Mock.new
      mock_hub.__expect(:publish_message) {|message| assert(message.is_a?(BuildStartedEvent))}
      mock_hub.__expect(:publish_message) {|message| assert(message.is_a?(BuildProgressEvent))}
      mock_hub.__expect(:publish_message) {|message| assert(message.is_a?(BuildProgressEvent))}
      mock_hub.__expect(:publish_message) {|message| 
        assert(message.is_a?(BuildCompleteEvent))
        assert_equal(Build::KILLED, message.build.status) 
      }

      mock_build_history = MockIt::Mock.new
      mock_build_history.__expect(:last_successful_build) {nil}

      @build_executor = BuildExecutor.new(mock_hub, mock_build_history)
      @build_executor.start
      @build_executor.put(@build) 

      wait_for { @build_executor.build_process_executing? } 

      assert(@build_executor.build_process_executing?) 
      @build_executor.kill_build_process 
      assert(!@build_executor.build_process_executing?) 
      @build_executor.shutdown
    end
    
    def test_when_build_scheduled_executes_sends_start_process_and_complete
      mock_scm = MockIt::Mock.new
      mock_scm.__expect(:working_dir) { "." }
      mock_scm.__expect(:changesets) {}
      mock_scm.__expect(:checkout) {}
      mock_scm.__expect(:working_dir) { "." }

      mock_hub = MockIt::Mock.new
      mock_hub.__expect(:publish_message) {|message| assert(message.is_a?(BuildStartedEvent))}
      mock_hub.__expect(:publish_message) {|message| 
        assert(message.is_a?(BuildProgressEvent))
        assert_equal("echo Hello world from DamageControl!", message.output.chomp.chomp(" "))
      }
      mock_hub.__expect(:publish_message) {|message| 
        assert(message.is_a?(BuildProgressEvent))
        assert_equal("Hello world from DamageControl!", message.output.chomp.chomp(" "))
      }
      mock_hub.__expect(:publish_message) {|message| assert(message.is_a?(BuildCompleteEvent))}

      @build.scm = mock_scm

      mock_build_history = MockIt::Mock.new
      mock_build_history.__expect(:last_successful_build) { |project_name|
        assert_equal("damagecontrolled", project_name)
        b = Build.new("damagecontrolled")
        b
      }

      @build_executor = BuildExecutor.new(mock_hub, mock_build_history)
      @build_executor.on_message(@build)

      mock_scm.__verify
      mock_hub.__verify
      mock_build_history.__verify
    end
    
    def test_failing_build_sends_build_complete_event_with_successful_flag_set_to_false
      mock_scm = MockIt::Mock.new
      mock_scm.__expect(:working_dir) { "." }
      mock_scm.__expect(:changesets) {}
      mock_scm.__expect(:checkout) {}
      mock_scm.__expect(:working_dir) { "." }

      mock_build_history = MockIt::Mock.new
      mock_build_history.__expect(:last_successful_build) { |project_name|
        assert_equal("damagecontrolled", project_name)
        b = Build.new("damagecontrolled")
        b
      }

      mock_hub = MockIt::Mock.new
      mock_hub.__setup(:publish_message) {|message|}

      @build_executor = BuildExecutor.new(mock_hub, mock_build_history)

      @build = Build.new("damagecontrolled", Time.now, { "build_command_line" => "bad_command"})
      @build.scm = mock_scm
      @build_executor.on_message(@build)
      # what happens for bad_command is different on windows and linux
      # windows? returns false on cygwin, so this doesn't work
#      if(windows?)
#        assert(messages_from_hub[-2].is_a?(BuildStartedEvent))
#      else
#        assert(messages_from_hub[-2].is_a?(BuildProgressEvent))
#      end
      assert_equal(Build::FAILED, @build.status)

      mock_scm.__verify
      mock_hub.__verify
      mock_build_history.__verify
    end
    
    def test_checks_out_and_determines_changeset_before_building      
      checkoutdir = "#{@basedir}/damagecontrolled/checkout/damagecontrolled"
      FileUtils.mkdir_p(checkoutdir)
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

      mock_hub = MockIt::Mock.new
      mock_hub.__expect(:publish_message) {|message| assert(message.is_a?(BuildStartedEvent))}
      mock_hub.__expect(:publish_message) {|message| assert(message.is_a?(BuildProgressEvent))}
      mock_hub.__expect(:publish_message) {|message| assert(message.is_a?(BuildProgressEvent))}
      mock_hub.__expect(:publish_message) {|message| assert(message.is_a?(BuildCompleteEvent))}
      
      @build_executor = BuildExecutor.new(mock_hub, mock_build_history)
      @build = Build.new("damagecontrolled", Time.now,
        { "build_command_line" => "echo hello world"})
      @build.scm = mock_scm
      @build.timestamp = current_build_time

      @build_executor.on_message(@build)
      
      assert_equal(nil, @build.error_message)
      assert_equal(Build::SUCCESSFUL, @build.status)
      
      mock_scm.__verify
      mock_hub.__verify
      mock_build_history.__verify
    end
    
    def ant
      windows? ? "ant.bat" : "ant"
    end
  end
end
