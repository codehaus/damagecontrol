require 'webrick'
require 'pebbles/MVCServlet'

module DamageControl
  class AbstractAdminServlet < Pebbles::MVCServlet
    def initialize(type, build_scheduler, build_history_repository)
      @type = type
      @build_scheduler = build_scheduler
      @build_history_repository = build_history_repository
    end
    
  protected
    
    def title
      ""
    end
    
    def tasks
      {}
    end
    
    def ritemesh_template
      "decorators/default.erb"
    end
    
    def assert_private
      raise "not privileged" if @type != :private
    end
  
    def private?
      @type == :private
    end
    
  private
    
    attr_reader :build_history_repository

  end
end
