require 'test/unit'
require 'pebbles/mockit'

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
        "build_command_line" => windows? ? "cmd /C echo Hello world from DamageControl!" : "echo Hello world from DamageControl!"
        })
    end
    
    def wait_for(timeout=5, &proc) 
      0.upto(timeout) do 
        return if proc.call 
        sleep 1 
      end 
    end
     
    def Xtest_can_kill_a_running_build 
      # this blocks forever
      @build.config["build_command_line"] = windows? ? "notepad" : "cat"
      @build.scm = NoSCM.new
      @build.scm.checkout_dir = "."

      channel = Pebbles::MulticastSpace.new
      channel.start
      
      build_history_repository = new_mock
      logdir = new_temp_dir
      build_history_repository.__expect(:stdout_file) {"#{logdir}/stdout.log"}
      build_history_repository.__expect(:stderr_file) {"#{logdir}/stderr.log"}
      build_history_repository.__expect(:last_completed_build) {nil}

      project_config_repository = new_mock
      project_config_repository.__setup(:checkout_dir) { |project_name| assert_equal("damagecontrolled", project_name); "some_dir" }
      project_config_repository.__expect(:peek_next_build_label) {45}
      project_config_repository.__expect(:inc_build_label) {45}

      @build_executor = BuildExecutor.new(
        'executor1', 
        channel, 
        project_config_repository,
        build_history_repository
      )
      # Make it run in a separate thread
      @build_executor.start

      @build_executor.put(@build) 
      wait_for { @build_executor.build_process_executing? } 
      assert(@build_executor.build_process_executing?) 
      @build_executor.kill_build_process 
      assert(!@build_executor.build_process_executing?) 
      
      sleep(10)
#      @build_executor.shutdown
    end
    
    def test_when_build_scheduled_executes_sends_start_process_and_complete
      mock_scm = new_mock
      mock_scm.__expect(:changesets) {cs = ChangeSets.new; cs.add(Change.new(nil,nil,nil,nil,Time.new.utc)); cs}
      mock_scm.__expect(:checkout) {}
      mock_scm.__expect(:label) { nil }

      channel = new_mock
      channel.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::DETERMINING_CHANGESETS, message.build.status)
        assert_nil(message.build.scm_commit_time)
      }
      channel.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::DETERMINING_CHANGESETS, message.build.status)
        assert(message.build.scm_commit_time)
      }
      channel.__expect(:put) {|message| assert(message.is_a?(BuildStartedEvent))}
      channel.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::CHECKING_OUT, message.build.status)
      }
      channel.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::BUILDING, message.build.status)
        assert_equal(23, message.build.label)
      }
      channel.__expect(:put) {|message| 
        assert(message.is_a?(StandardOutEvent), message)
      }
      channel.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::SUCCESSFUL, message.build.status)
      }
      channel.__expect(:put) {|message| 
        assert(message.is_a?(BuildCompleteEvent), message)
      }

      @build.scm = mock_scm

      build_history_repository = new_mock
      logdir = new_temp_dir
      build_history_repository.__expect(:stdout_file) {"#{logdir}/stdout.log"}
      build_history_repository.__expect(:stderr_file) {"#{logdir}/stderr.log"}

      build_history_repository.__expect(:last_completed_build) { |project_name|
        assert_equal("damagecontrolled", project_name)
        b = Build.new("damagecontrolled")
        b
      }
      
      @build_executor = BuildExecutor.new(
        'executor1', 
        channel, 
        new_mock.__setup(:checkout_dir) {"some_dir"}.__expect(:peek_next_build_label) {23}.__expect(:inc_build_label) {23},
        build_history_repository
      )
      @build_executor.on_message(@build)
    end
    
    def test_failing_build_sends_build_complete_event_with_successful_flag_set_to_false
      mock_scm = new_mock
      mock_scm.__expect(:changesets) {ChangeSets.new}
      mock_scm.__expect(:checkout) {}
      mock_scm.__expect(:label) {"23"}

      build_history_repository = new_mock
      logdir = new_temp_dir
      build_history_repository.__expect(:stdout_file) {"#{logdir}/stdout.log"}
      build_history_repository.__expect(:stderr_file) {"#{logdir}/stderr.log"}
      build_history_repository.__expect(:last_completed_build) { |project_name|
        assert_equal("damagecontrolled", project_name)
        b = Build.new("damagecontrolled")
        b
      }

      t = Time.new.utc
      build_history_repository.__expect(:last_commit_time){t}
      
      prev = Build.new
      prev.label = "23.2"
      build_history_repository.__expect(:prev){prev}

      channel = new_mock
      channel.__setup(:put) {|message|}

      @build_executor = BuildExecutor.new(
        'executor1', 
        channel, 
        new_mock.__setup(:checkout_dir) {"some_dir"}.__expect(:peek_next_build_label){-1},
        build_history_repository
      )

      @build = Build.new("damagecontrolled", { "build_command_line" => "bad_command"})
      @build.scm = mock_scm
      @build_executor.on_message(@build)
      assert_equal(Build::FAILED, @build.status)
      assert_equal("23.3", @build.label)
      assert_equal(t, @build.scm_commit_time)
    end
    
    def test_checks_out_and_determines_changeset_before_building      
      checkoutdir = "#{@basedir}/damagecontrolled/checkout/damagecontrolled"
      FileUtils.mkdir_p(checkoutdir)
      last_build_time = Time.utc(2004, 04, 02, 12, 00, 00)
      current_build_time = Time.utc(2004, 04, 02, 13, 00, 00)
      
      build_history_repository = new_mock
      logdir = new_temp_dir
      build_history_repository.__expect(:stdout_file) {"#{logdir}/stdout.log"}
      build_history_repository.__expect(:stderr_file) {"#{logdir}/stderr.log"}
      build_history_repository.__expect(:last_completed_build) { |project_name|
        assert_equal("damagecontrolled", project_name)
        b = Build.new("damagecontrolled")
        b.scm_commit_time = last_build_time
        b
      }
      prev = Build.new
      prev.label = "39"
      build_history_repository.__expect(:prev){prev}

      mock_scm = new_mock.__setup(:working_dir) { checkoutdir }
      mock_scm.__expect(:changesets) {|checkout_dir, from_time, to_time|
        assert_equal("some_dir", checkout_dir)
        assert_equal(last_build_time + 1, from_time)
        assert_equal(nil, to_time)
        cs = ChangeSets.new; cs.add(Change.new(nil,nil,nil,nil,Time.new.utc)); cs
      }
      mock_scm.__expect(:checkout) {}
      mock_scm.__expect(:label) { "39" }

      channel = new_mock
      channel.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::DETERMINING_CHANGESETS, message.build.status)
        assert(message.build.scm_commit_time)
      }
      channel.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent), message)
      }
      channel.__expect(:put) {|message| 
        assert(message.is_a?(BuildStartedEvent), message)
      }
      channel.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent), message)
        assert_equal(Build::CHECKING_OUT, message.build.status)
      }
      channel.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::BUILDING, message.build.status)
        assert_equal("39.1", message.build.label)
      }
      channel.__expect(:put) {|message| 
        assert(message.is_a?(StandardOutEvent), message)
      }
      channel.__expect(:put) {|message| 
        assert(message.is_a?(BuildStateChangedEvent))
        assert_equal(Build::SUCCESSFUL, message.build.status)
      }
      channel.__expect(:put) {|message| 
        assert(message.is_a?(BuildCompleteEvent), message)
      }
      
      @build_executor = BuildExecutor.new(
        'executor1', 
        channel, 
        new_mock.__setup(:checkout_dir) { "some_dir" }.__expect(:peek_next_build_label){-1},
        build_history_repository
      )
      @build = Build.new("damagecontrolled",
        { "build_command_line" => windows? ? "cmd /C echo hello world" : "echo hello world"})
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
