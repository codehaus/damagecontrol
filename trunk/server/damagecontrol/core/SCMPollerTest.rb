require 'damagecontrol/util/HubTestHelper'
require 'damagecontrol/core/SCMPoller'

require 'test/unit'
require 'pebbles/mockit'

module DamageControl

  class SCMPollerTest < Test::Unit::TestCase
  
    include HubTestHelper

    def setup
      create_hub
      @to_verify = []
    end
    
    def to_verify(mock)
      @to_verify<<mock
      mock
    end
    
    def verify_all
      @to_verify.each{|m| m.__verify}
    end
    
    def new_mock
      to_verify(MockIt::Mock.new)
    end
    
    def teardown
      verify_all
    end
    
    def test_doesnt_check_scm_if_build_is_executing
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
      should_not_poll_scm.__expect_not_called(:changesets)
      
      poller = SCMPoller.new(hub,
        1,
        mock_scm_factory(should_not_poll_scm), 
        mock_project_config_repository(project_config_with_polling, 10), 
        mock_build_history_repository(10),
        build_scheduler)
        
      poller.force_tick(10)
    end
    
    def test_request_build_without_checking_if_there_is_no_completed_build
      should_not_poll_scm = new_mock
      should_not_poll_scm.__expect_not_called(:changesets)
      
      build_history_repository = new_mock
      build_history_repository.__expect(:last_completed_build) {|project_name|
        assert_equal("project", project_name)
        nil
      }
      
      poller = SCMPoller.new(hub,
        1,
        mock_scm_factory(should_not_poll_scm), 
        mock_project_config_repository(project_config_with_polling, 10), 
        build_history_repository,
        mock_build_scheduler)
        
      poller.force_tick(10)
      assert_message_types_from_hub([BuildRequestEvent])
    end
    
    def test_should_not_poll_projects_where_polling_hasnt_been_specified
      should_not_poll_scm = new_mock
      should_not_poll_scm.__expect_not_called(:changesets)
      
      poller = SCMPoller.new(hub,
        1,
        mock_scm_factory(should_not_poll_scm), 
        mock_project_config_repository(project_config_without_polling, 0), 
        mock_build_history_repository(10),
        mock_build_scheduler)
        
      poller.force_tick(10)
    end

    def test_should_not_poll_outside_polling_interval
      should_not_poll_scm = new_mock
      should_not_poll_scm.__expect_not_called(:changesets)
      
      poller = SCMPoller.new(hub,
        10,
        mock_scm_factory(should_not_poll_scm), 
        mock_project_config_repository(project_config_with_polling, 0), 
        mock_build_history_repository(10),
        mock_build_scheduler)
        
      poller.force_tick(15)
    end
    
    def test_should_poll_during_polling_interval
      should_poll_scm = new_mock
      should_poll_scm.__expect(:changesets) { |from, to| [] }
      
      poller = SCMPoller.new(hub,
        10,
        mock_scm_factory(should_poll_scm), 
        mock_project_config_repository(project_config_with_polling, 0),
        mock_build_history_repository(10),
        mock_build_scheduler)
        
      poller.force_tick(20)
    end
    
    def test_does_not_send_build_request_when_no_change_has_happened
      now = 1000
      last_build = 2000
      
      scm = new_mock
      scm.__expect(:changesets) { |from, to|
        assert_equal(Time.at(last_build), from)
        assert_equal(Time.at(now), to)
        ChangeSets.new([])
      }
            
      poller = SCMPoller.new(hub,
        1,
        mock_scm_factory(scm), 
        mock_project_config_repository(project_config_with_polling, now),
        mock_build_history_repository(last_build),
        mock_build_scheduler)
      
      poller.force_tick(now)
      
      assert_message_types_from_hub([])
    end
    
    def test_sends_build_request_when_changes_since_last_completed_build
      now = 1000
      last_build = 2000
      project_config = {}
      
      scm = new_mock
      scm.__expect(:changesets) { |from, to|
        assert_equal(Time.at(last_build), from)
        assert_equal(Time.at(now), to)
        ChangeSets.new([ChangeSet.new([Change.new])])
      }
      
      poller = SCMPoller.new(hub, 
        1,
        mock_scm_factory(scm), 
        mock_project_config_repository(project_config_with_polling, now),
        mock_build_history_repository(last_build),
        mock_build_scheduler)
        
      poller.poll_project("project", Time.at(now))
      
      assert_message_types_from_hub([BuildRequestEvent])
    end
    
    def project_config_with_polling
      { "polling" => "true" }
    end
    
    def project_config_without_polling
      { "polling" => "false" }
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
        Build.new("project", last_build)
      }
      build_history_repository
    end
    
    def mock_scm_factory(scm)
      scm_factory = MockIt::Mock.new
      scm_factory.__setup(:get_scm) {|config, working_dir|
        assert_equal("checkoutdir", working_dir)
        scm
      }
      to_verify(scm_factory)
      scm_factory
    end
    
    def mock_project_config_repository(config, now)
      project_config_repository = new_mock
      project_config_repository.__setup(:project_names) { ["project"] }
      project_config_repository.__setup(:project_config) {|project_name|
        assert_equal("project", project_name)
        config
      }
      project_config_repository.__setup(:checkout_dir) {|project_name|
        assert_equal("project", project_name)
        "checkoutdir"
      }
      project_config_repository.__setup(:create_build) {|project_name, time|
        assert_equal("project", project_name)
        assert_equal(now, time.to_i)
        Build.new("project", time)
      }
      project_config_repository
    end
    
  end

end