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
      meth 'array history(string)', 'takes project name as string, returns an array of timestamps.', 'history'
      meth 'array project_names()', 'returns the list of projects registered with the damagecontrol instance as an array of strings.', 'project_names'
      meth 'struct current_build(string)', 'takes a project name as string, returns the currently executing build', 'current_build'
      meth 'struct last_completed_build(string)', 'takes a project name as a string, returns the last completed build', 'last_completed_build'
      meth 'struct last_successful_build(string)', 'takes a project name as a string, returns the last successful build', 'last_successful_build'
    }
    
    def initialize(xmlrpc_servlet, build_history_repository)
      @build_history_repository = build_history_repository
      xmlrpc_servlet.add_handler(INTERFACE, self)
    end
    
    def history(project_name)
      clean_for_marshal(@build_history_repository.history(project_name))
    end
    
    def project_names
      clean_for_marshal(@build_history_repository.project_names)
    end
    
    def current_build(project_name)
      clean_for_marshal(@build_history_repository.current_build(project_name))
    end
    
    def last_completed_build(project_name)
      clean_for_marshal(@build_history_repository.last_completed_build(project_name))
    end
    
    def last_successful_build(project_name)
      clean_for_marshal(@build_history_repository.last_successful_build(project_name))
    end
    
    def clean_for_marshal(o)
      case o
      when Build
        build = o.dup
        build.scm = nil
        # HACK OF DEATH:
        # some xmlrpc implementations get very confused by an empty struct
        # so we'll patch it by adding a pointless property in it
        # (did that take me like one day to figure out?!)
        # -- Jon Tirsen
        build.config["ignore"]="me" if o.config.empty?
        build
      when Array
        o.collect {|s| clean_for_marshal(s)}
      else
        o
      end
    end
    
  end

end
end
