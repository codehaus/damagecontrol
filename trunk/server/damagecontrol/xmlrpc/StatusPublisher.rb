require 'xmlrpc/server'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/BuildHistoryRepository'

# Exposes a BuildHistoryRepository to XML-RPC
# 
# Authors: Steven Meyfroidt, Aslak Hellesoy, Jon Tirsen
module DamageControl
module XMLRPC  

  class StatusPublisher
  
    INTERFACE = ::XMLRPC::interface("status") {
      meth 'array history(string)', 'takes project name as string, returns an array of build.', 'history'
      meth 'array project_names()', 'returns the list of projects registered with the damagecontrol instance as an array of strings.', 'project_names'
      meth 'struct current_build(string)', 'takes a project name as string, returns the currently executing build', 'current_build'
      meth 'struct last_completed_build(string)', 'takes a project name as a string, returns the last completed build', 'last_completed_build'
      meth 'struct last_successful_build(string)', 'takes a project name as a string, returns the last successful build', 'last_successful_build'
      meth 'array global_search(string)', 'returns the build containing text in all projects', 'global_search'
    }
    
    def initialize(xmlrpc_servlet, build_history_repository)
      @build_history_repository = build_history_repository
      xmlrpc_servlet.add_handler(INTERFACE, self)
    end
    
    def history(project_name)
      @build_history_repository.history(project_name)
    end
    
    def current_build(project_name)
      @build_history_repository.current_build(project_name)
    end
    
    def project_names
      @build_history_repository.project_names
    end
    
    def last_completed_build(project_name)
      @build_history_repository.last_completed_build(project_name)
    end
    
    def last_successful_build(project_name)
      @build_history_repository.last_successful_build(project_name)
    end
    
    def global_search(regexp)
      @build_history_repository.search(Regexp.new(regexp))
    end
    
  end

end
end
