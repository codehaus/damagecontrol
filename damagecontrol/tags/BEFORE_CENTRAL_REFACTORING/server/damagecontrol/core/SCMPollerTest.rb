require 'test/unit'

require 'mockit'

require 'damagecontrol/HubTestHelper'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/Build'
require 'damagecontrol/Timer'

module DamageControl

  class SCMPoller
    include TimerMixin
    
    def initialize(hub, scm, project_name, scm_spec, build_succesful_registry)
      @hub = hub
      @scm = scm
      @project_name = project_name
      @scm_spec = scm_spec
      @build_succesful_registry = build_succesful_registry
    end
  
    def tick(time)
      changes = @scm.get_changes(@scm_spec, @build_succesful_registry.last_succesful_build(@project_name), time)
      @hub.publish_message(BuildRequestEvent.new(Build.new)) if !changes.empty?
    end
  end
  
  class BuildSuccesfulRegistry
    def initialize
      @last_succesful_builds = {}
    end
    
    def set_last_successful_build(project_name, time)
      @last_succesful_builds[project_name] = time
    end
    
    def last_succesful_build(project_name)
      @last_succesful_builds[project_name]
    end
  end

  class SCMPollerTest < Test::Unit::TestCase
  
    include HubTestHelper

    def setup
      create_hub
    end

    def test_does_not_send_build_request_when_no_change_has_happened
      now = 1000
      last_succesful_build = 2000
      
      scm = MockIt::Mock.new
      scm.__expect(:get_changes) { |spec, from, to|
        assert_equal(last_succesful_build, from)
        assert_equal(now, to)
        assert_equal("scm_spec", spec)
        [ ]
      }
      
      build_succesful_registry = BuildSuccesfulRegistry.new
      build_succesful_registry.set_last_successful_build("project_name", last_succesful_build)
      
      poller = SCMPoller.new(hub, scm, "project_name", "scm_spec", build_succesful_registry)
      
      poller.tick(now)
      
      assert_message_types_from_hub([])
      scm.__verify
    end
    
    def test_sends_build_request_when_change_happens_in_project
      
      scm = MockIt::Mock.new
      scm.__expect(:get_changes) { |spec, from, to|
        assert_equal("scm_spec", spec)
        [ Modification.new ]
      }
      
      poller = SCMPoller.new(hub, scm, "project_name", "scm_spec", BuildSuccesfulRegistry.new)
      
      poller.force_tick
      
      assert_message_types_from_hub([BuildRequestEvent])
      scm.__verify
    end
  
  end

end