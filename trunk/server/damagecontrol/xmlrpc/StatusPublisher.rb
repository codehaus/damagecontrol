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
      meth 'array project_names()', 'returns the list of projects registered with the damagecontrol instasnce as an array of strings.', 'project_names'
      meth 'struct current_build(string)', 'takes a project name as string, returns the currently executing build', 'current_build'
      meth 'struct last_completed_build(string)', 'takes a project name as a string, returns the last completed build', 'last_completed_build'
      meth 'struct last_successful_build(string)', 'takes a project name as a string, returns the last successful build', 'last_successful_build'
    }

    def initialize(xmlrpc_servlet, build_history_repository)
      xmlrpc_servlet.add_handler(INTERFACE, build_history_repository)
    end
  end

end
end
