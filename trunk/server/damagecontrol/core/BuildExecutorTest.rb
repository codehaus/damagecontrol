require 'test/unit'
require 'pebbles/mockit'

require 'fileutils'

require 'damagecontrol/core/Build'
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
    include MockIt
  
    def setup
      @basedir = new_temp_dir("BuildExecutorTest")
      @build = Build.new("damagecontrolled", {
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
      @build.scm = NoSCM.new
      @build.scm.checkout_dir = "."

      mock_hub = new_mock
      mock_hub.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::DETERMINING_CHANGESETS, message.build.status)
        assert_nil(message.build.scm_commit_time)
      }
      mock_hub.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::DETERMINING_CHANGESETS, message.build.status)
        assert(message.build.scm_commit_time)
      }
      mock_hub.__expect(:put) {|message| assert(message.is_a?(BuildStartedEvent))}
      mock_hub.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::CHECKING_OUT, message.build.status)
      }
      mock_hub.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::BUILDING, message.build.status)
      }
      mock_hub.__expect(:put) {|message| assert(message.is_a?(BuildProgressEvent))}
      mock_hub.__expect(:put) {|message| assert(message.is_a?(BuildErrorEvent), "message was #{message}")}
      mock_hub.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::KILLED, message.build.status) 
      }
      mock_hub.__expect(:put) {|message| 
        assert(message.is_a?(BuildCompleteEvent))
        assert_equal(Build::KILLED, message.build.status) 
      }

      mock_build_history = new_mock
      mock_build_history.__expect(:last_successful_build) {nil}

      @build_executor = BuildExecutor.new(
        'executor1', 
        mock_hub, 
        new_mock.__setup(:checkout_dir) { |project_name| assert_equal("damagecontrolled", project_name); "some_dir" },
        mock_build_history
      )
      @build_executor.start
      @build_executor.put(@build) 

      wait_for { @build_executor.build_process_executing? } 

      assert(@build_executor.build_process_executing?) 
      @build_executor.kill_build_process 
      assert(!@build_executor.build_process_executing?) 
      @build_executor.shutdown
    end
    
    def test_when_build_scheduled_executes_sends_start_process_and_complete
      mock_scm = new_mock
      mock_scm.__expect(:changesets) {cs = ChangeSets.new; cs.add(Change.new(nil,nil,nil,nil,Time.new.utc)); cs}
      mock_scm.__expect(:checkout) {}
      mock_scm.__expect(:label) {}

      mock_hub = new_mock
      mock_hub.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::DETERMINING_CHANGESETS, message.build.status)
        assert_nil(message.build.scm_commit_time)
      }
      mock_hub.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::DETERMINING_CHANGESETS, message.build.status)
        assert(message.build.scm_commit_time)
      }
      mock_hub.__expect(:put) {|message| assert(message.is_a?(BuildStartedEvent))}
      mock_hub.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::CHECKING_OUT, message.build.status)
      }
      mock_hub.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::BUILDING, message.build.status)
      }
      mock_hub.__expect(:put) {|message| 
        assert(message.is_a?(BuildProgressEvent))
        assert_equal("echo Hello world from DamageControl!", message.output.chomp.chomp(" "))
      }
      mock_hub.__expect(:put) {|message| 
        assert(message.is_a?(BuildProgressEvent))
        assert_equal("Hello world from DamageControl!", message.output.chomp.chomp(" "))
      }
      mock_hub.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::SUCCESSFUL, message.build.status)
      }
      mock_hub.__expect(:put) {|message| assert(message.is_a?(BuildCompleteEvent))}

      @build.scm = mock_scm

      mock_build_history = new_mock
      mock_build_history.__expect(:last_successful_build) { |project_name|
        assert_equal("damagecontrolled", project_name)
        b = Build.new("damagecontrolled")
        b
      }

      @build_executor = BuildExecutor.new(
        'executor1', 
        mock_hub, 
        new_mock.__setup(:checkout_dir) {"some_dir"},
        mock_build_history
      )
      @build_executor.on_message(@build)
    end
    
    def test_failing_build_sends_build_complete_event_with_successful_flag_set_to_false
      mock_scm = new_mock
      mock_scm.__expect(:changesets) {ChangeSets.new}
      mock_scm.__expect(:checkout) {}

      mock_build_history = new_mock
      mock_build_history.__expect(:last_successful_build) { |project_name|
        assert_equal("damagecontrolled", project_name)
        b = Build.new("damagecontrolled")
        b
      }

      mock_hub = new_mock
      mock_hub.__setup(:put) {|message|}

      @build_executor = BuildExecutor.new(
        'executor1', 
        mock_hub, 
        new_mock.__setup(:checkout_dir) {"some_dir"},
        mock_build_history
      )

      @build = Build.new("damagecontrolled", { "build_command_line" => "bad_command"})
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
    end
    
    def test_checks_out_and_determines_changeset_before_building      
      checkoutdir = "#{@basedir}/damagecontrolled/checkout/damagecontrolled"
      FileUtils.mkdir_p(checkoutdir)
      last_build_time = Time.utc(2004, 04, 02, 12, 00, 00)
      current_build_time = Time.utc(2004, 04, 02, 13, 00, 00)
      
      mock_build_history = new_mock.__expect(:last_successful_build) { |project_name|
        assert_equal("damagecontrolled", project_name)
        b = Build.new("damagecontrolled")
        b.scm_commit_time = last_build_time
        b
      }

      mock_scm = new_mock.__setup(:working_dir) { checkoutdir }
      mock_scm.__expect(:changesets) {|checkout_dir, from_time, to_time|
        assert_equal("some_dir", checkout_dir)
        assert_equal(last_build_time + 1, from_time)
        assert_equal(nil, to_time)
        cs = ChangeSets.new; cs.add(Change.new(nil,nil,nil,nil,Time.new.utc)); cs
      }
      mock_scm.__expect(:checkout) {}
      mock_scm.__expect(:label) {}

      mock_hub = new_mock
      mock_hub.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::DETERMINING_CHANGESETS, message.build.status)
        assert(message.build.scm_commit_time)
      }
      mock_hub.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::DETERMINING_CHANGESETS, message.build.status)
        assert(message.build.scm_commit_time)
      }
      mock_hub.__expect(:put) {|message| assert(message.is_a?(BuildStartedEvent))}
      mock_hub.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::CHECKING_OUT, message.build.status)
      }
      mock_hub.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::BUILDING, message.build.status)
      }
      mock_hub.__expect(:put) {|message| assert(message.is_a?(BuildProgressEvent), message)}
      mock_hub.__expect(:put) {|message| assert(message.is_a?(BuildProgressEvent), message)}
      mock_hub.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::SUCCESSFUL, message.build.status)
      }
      mock_hub.__expect(:put) {|message| assert(message.is_a?(BuildCompleteEvent), message)}
      
      @build_executor = BuildExecutor.new(
        'executor1', 
        mock_hub, 
        new_mock.__setup(:checkout_dir) { "some_dir" },
        mock_build_history
      )
      @build = Build.new("damagecontrolled",
        { "build_command_line" => "echo hello world"})
      @build.scm = mock_scm
      @build.scm_commit_time = current_build_time

      @build_executor.on_message(@build)
      
      assert_equal(nil, @build.error_message)
      assert_equal(Build::SUCCESSFUL, @build.status)
    end
    
    def test_can_execute_builds_with_matching_executor_selector
      e = BuildExecutor.new("executor1", new_mock, new_mock, new_mock)
      assert(e.can_execute?(@build))
      @build.config["executor_selector"] = ".*"
      assert(e.can_execute?(@build))
      @build.config["executor_selector"] = ".*1"
      assert(e.can_execute?(@build))
      @build.config["executor_selector"] = "executor2"
      assert(!e.can_execute?(@build))
      @build.config["executor_selector"] = "n.*"
      assert(!e.can_execute?(@build))
    end
    
    def ant
      windows? ? "ant.bat" : "ant"
    end
  end
end
