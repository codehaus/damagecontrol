require 'timeout'
require 'test/unit'
require 'pebbles/mockit'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildExecutor'
require 'damagecontrol/core/BuildHistoryRepository'
require 'damagecontrol/core/ProjectConfigRepository'
require 'damagecontrol/core/ProjectDirectories'
require 'damagecontrol/scm/NoSCM'
require 'damagecontrol/scm/Changes'
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
      # cat blocks forever
      @build.config["build_command_line"] = "cat"
      mock_hub = new_mock
      mock_hub.__expect(:put) {|message| assert(message.is_a?(BuildStartedEvent))}
      mock_hub.__expect(:put) {|message| assert(message.is_a?(BuildProgressEvent))}
      mock_hub.__expect(:put) {|message| assert(message.is_a?(BuildErrorEvent), "message was #{message}")}

      @build.scm = new_mock.__expect(:label){"a_label"}

      mock_hub.__expect(:put) {|message| 
        assert(message.is_a?(BuildCompleteEvent))
        assert_equal(Build::KILLED, message.build.status) 
      }

      build_executor = BuildExecutor.new(
        'executor1', 
        mock_hub, 
        new_mock.__expect(:checkout_dir).__expect(:checkout_dir)
      )
      build_executor.start
      build_executor.put(@build) 

      wait_for { build_executor.build_process_executing? } 

      assert(build_executor.build_process_executing?) 
      build_executor.kill_build_process 
      assert(!build_executor.build_process_executing?) 
      build_executor.shutdown
    end
    
    def test_when_build_scheduled_executes_sends_start_process_and_complete
      mock_hub = new_mock
      mock_hub.__expect(:put) {|message| assert(message.is_a?(BuildStartedEvent))}
      mock_hub.__expect(:put) {|message| 
        assert(message.is_a?(BuildProgressEvent))
        assert_equal("echo Hello world from DamageControl!", message.output.chomp.chomp(" "))
      }
      mock_hub.__expect(:put) {|message| 
        assert(message.is_a?(BuildProgressEvent))
        assert_equal("Hello world from DamageControl!", message.output.chomp.chomp(" "))
      }
      mock_hub.__expect(:put) {|message| assert(message.is_a?(BuildCompleteEvent))}

      @build.scm = new_mock.__expect(:label) {"a_label"}

      build_executor = BuildExecutor.new(
        'executor1', 
        mock_hub, 
        new_mock.__setup(:checkout_dir) {"target"}
      )
      build_executor.on_message(@build)
    end
    
    def test_failing_build_sends_build_complete_event_with_successful_flag_set_to_false
      
      mock_hub = new_mock
      mock_hub.__setup(:put) {|message|}

      build_executor = BuildExecutor.new(
        'executor1', 
        mock_hub, 
        new_mock.__setup(:checkout_dir) {"target"}
      )

      @build = Build.new("damagecontrolled", { "build_command_line" => "bad_command"})
      @build.scm = new_mock.__expect(:label) {"a_label"}
      build_executor.on_message(@build)
      # what happens for bad_command is different on windows and linux
      # windows? returns false on cygwin, so this doesn't work
#      if(windows?)
#        assert(messages_from_hub[-2].is_a?(BuildStartedEvent))
#      else
#        assert(messages_from_hub[-2].is_a?(BuildProgressEvent))
#      end
      assert_equal(Build::FAILED, @build.status)
    end
    
    def test_reports_progress
      current_build_time = Time.utc(2004, 04, 02, 13, 00, 00)
      
      mock_scm = new_mock
      mock_scm.__expect(:label) {}

      mock_hub = new_mock
      mock_hub.__expect(:put) {|message| assert(message.is_a?(BuildStartedEvent))}
      mock_hub.__expect(:put) {|message| assert(message.is_a?(BuildProgressEvent))}
      mock_hub.__expect(:put) {|message| assert(message.is_a?(BuildProgressEvent))}
      mock_hub.__expect(:put) {|message| assert(message.is_a?(BuildCompleteEvent))}
      
      build_executor = BuildExecutor.new(
        'executor1', 
        mock_hub, 
        new_mock.__expect(:checkout_dir).__expect(:checkout_dir)
      )
      @build = Build.new("damagecontrolled",
        { "build_command_line" => "echo hello world"})
      @build.scm = mock_scm
      @build.dc_start_time = current_build_time

      build_executor.on_message(@build)
      
      assert_equal(nil, @build.error_message)
      assert_equal(Build::SUCCESSFUL, @build.status)
    end
    
    def test_can_execute_builds_with_matching_executor_selector
      e = BuildExecutor.new(
        "executor1", 
        new_mock, 
        new_mock
      )
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
