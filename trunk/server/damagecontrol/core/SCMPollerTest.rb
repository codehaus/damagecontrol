require 'damagecontrol/core/SCMPoller'

require 'test/unit'
require 'pebbles/mockit'

module DamageControl

  class SCMPollerTest < Test::Unit::TestCase
  
    include MockIt

    def test_doesnt_check_scm_if_build_is_executing
      hub = new_mock
      build_scheduler = new_mock
      build_scheduler.__expect(:project_scheduled?) {|project_name|
        assert_equal("project", project_name)
        false
      }
      build_scheduler.__expect(:project_building?) {|project_name|
        assert_equal("project", project_name)
        true
      }
      should_not_poll_scm = new_mock
      
      poller = SCMPoller.new(hub,
        1,
        new_mock,
        project_config_repository_with_one_project_built_at(project_config_with_polling, should_not_poll_scm), 
        mock_build_history_repository(nil),
        build_scheduler)
        
      poller.tick(nil)

    end
    
    def test_request_build_without_checking_if_there_is_no_completed_build
      hub = new_mock
      should_not_poll_scm = new_mock
      
      build_history_repository = new_mock
      build_history_repository.__expect(:last_completed_build) {|project_name|
        assert_equal("project", project_name)
        nil
      }
      
      poller = SCMPoller.new(hub,
        1,
        new_mock,
        project_config_repository_with_one_project_built_at(project_config_with_polling, should_not_poll_scm), 
        build_history_repository,
        mock_build_scheduler)
        
      hub.__expect(:put) do |message| 
        assert(message.is_a?(BuildRequestEvent))
      end
      poller.tick(nil)
    end
    
    def test_should_not_poll_projects_where_polling_hasnt_been_specified
      hub = new_mock
      should_not_poll_scm = new_mock
      
      poller = SCMPoller.new(hub,
        1,
        new_mock,
        project_config_repository_with_one_project_built_at(project_config_without_polling, should_not_poll_scm), 
        mock_build_history_repository(nil),
        mock_build_scheduler)
        
      poller.tick(nil)

    end

    def TODO_test_should_not_poll_outside_polling_interval
      hub = new_mock
      should_not_poll_scm = new_mock
      
      poller = SCMPoller.new(hub,
        30,
        new_mock,
        project_config_repository_with_one_project_built_at(project_config_with_polling, should_not_poll_scm), 
        mock_build_history_repository(nil),
        mock_build_scheduler)
        
      poller.tick(nil)

    end
    
    def test_should_poll_during_polling_interval
      hub = new_mock
      should_poll_scm = new_mock
      should_poll_scm.__expect(:uptodate?) { true }
      
      poller = SCMPoller.new(hub,
        10,
        new_mock.__expect(:checkout_dir) { |project_name| assert_equal("project", project_name); "some_dir" },
        project_config_repository_with_one_project_built_at(project_config_with_polling, should_poll_scm),
        mock_build_history_repository(nil),
        mock_build_scheduler)
        
      poller.tick(nil)

    end
    
    def test_does_not_send_build_request_when_no_change_has_happened
      hub = new_mock
      last_build = Time.new.utc
      
      scm = new_mock
      scm.__expect(:uptodate?) { |checkout_dir, from, to|
        assert_equal("some_dir", checkout_dir)
        assert_equal(last_build, from)
        assert_equal(nil, to)
        true
      }
            
      poller = SCMPoller.new(hub,
        1,
        new_mock.__expect(:checkout_dir) { |project_name| assert_equal("project", project_name); "some_dir" },
        project_config_repository_with_one_project_built_at(project_config_with_polling, scm),
        mock_build_history_repository(last_build),
        mock_build_scheduler)
      
      poller.tick(nil)
      
    end
    
    def test_sends_build_request_when_changes_since_last_completed_build
      hub = new_mock
      last_build = Time.new.utc
      project_config = {}
      
      scm = new_mock
      scm.__expect(:uptodate?) { |checkout_dir, from, to|
        assert_equal("some_dir", checkout_dir)
        assert_equal(last_build, from)
        assert_equal(nil, to)
        false
      }
      scm.__expect(:changesets) { |checkout_dir, from, to|
        assert_equal("some_dir", checkout_dir)
        assert_equal(Time.at(last_build), from)
        assert_equal(nil, to)
        ChangeSets.new([ChangeSet.new([Change.new])])
      }
      
      poller = SCMPoller.new(hub, 
        1,
        new_mock.__expect(:checkout_dir) { |project_name| assert_equal("project", project_name); "some_dir" },
        project_config_repository_with_one_project_built_at(project_config_with_polling, scm),
        mock_build_history_repository(last_build),
        mock_build_scheduler)
        
      hub.__expect(:put) do |message| 
        assert(message.is_a?(BuildRequestEvent))
      end

      poller.poll_project("project")
      
    end
    
    def project_config_with_polling
      { "polling" => true }
    end
    
    def project_config_without_polling
      { "polling" => false }
    end
    
    def mock_build_scheduler
      build_scheduler = new_mock
      build_scheduler.__expect(:project_scheduled?) {|project_name|
        assert_equal("project", project_name)
        false
      }
      build_scheduler.__expect(:project_building?) {|project_name|
        assert_equal("project", project_name)
        false
      }
      build_scheduler
    end
    
    def mock_build_history_repository(last_build)
      build_history_repository = new_mock
      build_history_repository.__setup(:last_completed_build) {|project_name|
        assert_equal("project", project_name)
        build = Build.new("project")
        build.scm_commit_time = last_build
        build
      }
      build_history_repository
    end
        
    def project_config_repository_with_one_project_built_at(config, scm)
      project_config_repository = new_mock
      project_config_repository.__setup(:project_names) { ["project"] }
      project_config_repository.__setup(:project_config) {|project_name|
        assert_equal("project", project_name)
        config
      }
      project_config_repository.__setup(:create_scm) {|project_name|
        assert_equal("project", project_name)
        scm
      }
      project_config_repository.__setup(:checkout_dir) {|project_name|
        assert_equal("project", project_name)
        "checkoutdir"
      }
      project_config_repository.__setup(:create_build) {|project_name|
        assert_equal("project", project_name)
        Build.new("project")
      }
      project_config_repository
    end
    
  end

end