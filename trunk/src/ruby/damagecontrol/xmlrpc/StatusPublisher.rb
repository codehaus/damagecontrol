require 'xmlrpc/server'
require 'damagecontrol/Build'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/BuildHistoryRepository'

::XMLRPC::Config::ENABLE_NIL_CREATE = true

# Exposes a BuildHistoryRepository to XML-RPC
# 
# Authors: Steven Meyfroidt, Aslak Hellesoy, Jon Tirsen
module DamageControl
module XMLRPC  

  class StatusPublisher
  
    INTERFACE = ::XMLRPC::interface("status") {
      meth 'struct get_build_list_map(string)', 'returns a map of builds, project name as key.', 'get_build_list_map'
      meth 'array get_project_names()', 'returns an array of project names.', 'get_project_names'
      meth 'struct get_current_build(string)', 'returns a map of array of build, project name as key.', 'current_build'
      meth 'struct get_last_completed_build(string)', 'returns a map of array of build, project name as key.', 'last_completed_build'
    }

    def initialize(xmlrpc_servlet, build_history_repository)
      xmlrpc_servlet.add_handler(INTERFACE, build_history_repository)
    end
  end

end
end
