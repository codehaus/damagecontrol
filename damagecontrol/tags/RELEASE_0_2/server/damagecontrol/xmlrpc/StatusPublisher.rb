require 'xmlrpc/server'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/BuildHistoryRepository'

::XMLRPC::Config::ENABLE_NIL_CREATE = true

# Exposes a BuildHistoryRepository to XML-RPC
# 
# Authors: Steven Meyfroidt, Aslak Hellesoy, Jon Tirsen
module DamageControl
module XMLRPC  

  class StatusPublisher
  
    INTERFACE = ::XMLRPC::interface("status") {
      meth 'array history(string)', 'returns an array of build.', 'history'
      meth 'array project_names()', 'returns an array of project names.', 'project_names'
      meth 'struct current_build(string)', 'current_build', 'current_build'
      meth 'struct last_completed_build(string)', 'last_completed_build', 'last_completed_build'
      meth 'struct last_successful_build(string)', 'last_successful_build', 'last_successful_build'
    }

    def initialize(xmlrpc_servlet, build_history_repository)
      xmlrpc_servlet.add_handler(INTERFACE, build_history_repository)
    end
  end

end
end
