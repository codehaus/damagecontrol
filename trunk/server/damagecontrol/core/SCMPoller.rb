require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/Timer'

module DamageControl

  class SCMPoller
    include TimerMixin
    
    def initialize(hub, polling_interval, scm_factory, project_config_repository, build_history_repository)
      @hub = hub
      @polling_interval = polling_interval
      @scm_factory = scm_factory
      @project_config_repository = project_config_repository
      @build_history_repository = build_history_repository
    end
  
    def tick(time)
      @project_config_repository.project_names.each {|project_name| poll_project(project_name, Time.at(time))}
    end
    
    def polling_interval(project_name)
      # implement project specific polling intervals here
      @polling_interval
    end
    
    def should_poll?(project_name, time)
      return false unless project_config(project_name)["polling"]
      return false unless eval(project_config(project_name)["polling"])
      time.to_i % polling_interval(project_name) == 0
    end
    
    def project_config(project_name)
      @project_config_repository.project_config(project_name)
    end
    
    def poll_project(project_name, time)
      return unless should_poll?(project_name, time)
      scm = @scm_factory.create_scm(project_config(project_name), @project_config_repository.checkout_dir(project_name))
      changesets = scm.changesets(@build_history_repository.last_completed_build(project_name).timestamp_as_time, time)
      @hub.publish_message(BuildRequestEvent.new(Build.new)) unless changesets.empty?
    end
  end
end