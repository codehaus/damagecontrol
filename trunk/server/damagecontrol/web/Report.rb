require 'pebbles/MVCServlet'

module DamageControl
  class Report
    include Pebbles::SimpleERB
    
    def initialize(selected_build, project_config_repository)
      @selected_build = selected_build
      @project_config_repository = project_config_repository
    end
    
    def id
      raise "have to implement"
    end
    
    def available?
      !selected_build.nil?
    end
    
    def title
      id.capitalize
    end
    
    def content
      ""
    end
    
    def icon
      nil
    end
    
    def extra_css
      []
    end
    
    def ==(other_tab)
      return false unless other_tab.is_a? self.class
      id == other_tab.id
    end
    
  protected

    attr_reader :selected_build
    attr_reader :project_config_repository

    def project_config
      project_config_repository.project_config(project_name)
    end

    def project_name
      selected_build.project_name
    end

    def template_dir
      File.dirname(__FILE__)
    end
    
  end
end