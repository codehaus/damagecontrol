require 'webrick'
require 'pebbles/MVCServlet'

module DamageControl
  class AbstractAdminServlet < Pebbles::MVCServlet
    def initialize(type)
      @type = type
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
  end
end
