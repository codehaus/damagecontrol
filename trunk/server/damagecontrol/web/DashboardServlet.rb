require 'webrick'
require 'erb'
require 'pebbles/MVCServlet'

module DamageControl  
  class DashboardServlet < Pebbles::MVCServlet
    def initialize(build_history_repository, project_config_repository)
      @build_history_repository = build_history_repository
      @project_config_repository = project_config_repository
    end

    def templatedir
      File.dirname(__FILE__)
    end
  
    def default_action
      erb("dashboard.erb", binding)
    end
    
    private
    
    attr_reader :build_history_repository
    attr_reader :project_config_repository
    
  end
end
