require 'xmlrpc/server'
require 'damagecontrol/Build'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/BuildHistoryRepository'

# Exposes a BuildHistoryRepository to XML-RPC
# 
# Authors: Steven Meyfroidt, Aslak Hellesoy
module DamageControl

  class XMLRPCStatusPublisher
  
    INTERFACE = XMLRPC::interface("status") {
      meth 'struct get_build_list_map(string)', 'returns a map of array of build, project name as key.', 'get_build_list_map'
      meth 'array get_project_names()', 'returns an array of project names.', 'get_project_names'
    }

    def initialize(xmlrpc_servlet, build_history_publisher)
      xmlrpc_servlet.add_handler(INTERFACE, build_history_publisher)
    end
  end
end
