require 'damagecontrol/core/SCMPoller'
require 'damagecontrol/core/BuildEvents'

require 'test/unit'
require 'pebbles/mockit'

module DamageControl

  class SCMPollerTest < Test::Unit::TestCase
  
    include MockIt

    def test_doesnt_checkout_if_build_is_executing
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
      
      last_commit = Time.new.utc
      
      poller = SCMPoller.new(
        hub,
        1,
        mock_project_config_repository(project_config_with_polling(last_commit), 10), 
        build_scheduler
      )
        
      poller.tick(10)

    end
    
    def test_should_request_build_without_checking_if_there_is_no_completed_build
      hub = new_mock.__expect(:publish_message) {|m| m.is_a?(DoCheckoutEvent)}
      
      build_history_repository = new_mock
      
      poller = SCMPoller.new(
        hub,
        1,
        mock_project_config_repository(project_config_with_polling(Time.new.utc), 10), 
        mock_build_scheduler
      )

      poller.tick(10)
    end
    
    def test_should_not_poll_projects_where_polling_hasnt_been_specified
      hub = new_mock
      
      poller = SCMPoller.new(
        hub,
        1,
        mock_project_config_repository(project_config_without_polling(nil), 30), 
        mock_build_scheduler
      )
        
      poller.tick(30)

    end

    def test_should_not_poll_outside_project_polling_interval
      hub = new_mock
      
      poller = SCMPoller.new(
        hub,
        30,
        mock_project_config_repository(project_config_with_polling(nil, 40), 35), 
        mock_build_scheduler
      )
        
      poller.tick(35)

    end
    
    def test_should_not_poll_outside_default_polling_interval
      hub = new_mock
      
      poller = SCMPoller.new(
        hub,
        40,
        mock_project_config_repository(project_config_with_polling(nil, nil), 35), 
        mock_build_scheduler
      )
        
      poller.tick(35)

    end
    
    def test_should_poll_during_project_polling_interval
      hub = new_mock.__expect(:publish_message) {|m| m.is_a?(DoCheckoutEvent)}
      
      poller = SCMPoller.new(
        hub,
        40,
        mock_project_config_repository(project_config_with_polling(nil, 30), 35),
        mock_build_scheduler
      )
        
      poller.tick(35)

    end
    
    def test_should_poll_during_default_polling_interval
      hub = new_mock.__expect(:publish_message) {|m| m.is_a?(DoCheckoutEvent)}
      
      poller = SCMPoller.new(
        hub,
        30,
        mock_project_config_repository(project_config_with_polling(nil, nil), 35),
        mock_build_scheduler
      )
        
      poller.tick(35)

    end
    
    def test_does_not_send_build_request_when_no_change_has_happened      
      last_commit = Time.new.utc
    
      poller = SCMPoller.new(
        new_mock.__expect(:publish_message) {|m| m.is_a?(DoCheckoutEvent)},
        1,
        mock_project_config_repository(project_config_with_polling(last_commit), 10),
        mock_build_scheduler
      )
      
      poller.tick(10)
      
    end
    
    def test_sends_build_request_when_changes_since_last_completed_build
      last_commit = Time.new.utc
            
      hub = new_mock.__expect(:publish_message) {|m| m.is_a?(DoCheckoutEvent)}
      poller = SCMPoller.new(
        hub, 
        1,
        mock_project_config_repository(project_config_with_polling(last_commit), 10),
        mock_build_scheduler
      )
        
      poller.tick(10)
      
    end
    
    def project_config_with_polling(last_commit, interval=true)
      { "polling" => interval, "last_commit" => last_commit }
    end
    
    def project_config_without_polling(last_commit)
      { "polling" => false, "last_commit" => last_commit }
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
    
    def mock_project_config_repository(config, build_time)
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
      project_config_repository.__setup(:create_build) {|project_name|
        assert_equal("project", project_name)
        Build.new("project", build_time)
      }
      project_config_repository
    end
    
  end

end