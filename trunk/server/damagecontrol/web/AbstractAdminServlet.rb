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
  
    def auto_refresh_rate
      10
    end
  
    def auto_refresh?
      to_boolean(request.query['auto_refresh'])
    end
    
    def auto_refresh_url_prefix
      query_string = request.query_string
      return "?" if query_string.nil?
      query_string.gsub!(/&?auto_refresh=.*&?/, "")
      return "?" if query_string == ""
      "?#{query_string}&"
    end
    
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
    
    def breadcrumbs
      result = "<a href=\"dashboard\">Dashboard</a>"
      result << " > #{request.query['project_name']}" if request.query['project_name']
      result
    end
    
    def right_top_nav
      "<a href=\"root/<%= project_name %>/checkout\">Checked out files...</a>"
    end
    
  private
    
    attr_reader :build_history_repository

    def to_boolean(text)
      text && text == "true"
    end
  
  end
end
