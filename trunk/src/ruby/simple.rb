#!/usr/bin/env ruby

require 'xmlrpc/server'
require 'webrick'
 
$damagecontrol_home = File::expand_path('../..') 
$:<<"#{$damagecontrol_home}/src/ruby" 

require 'damagecontrol/Hub'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/BuildScheduler'
require 'damagecontrol/SocketTrigger'
require 'damagecontrol/HostVerifyingHandler'
require 'damagecontrol/XMLRPCTrigger'

include DamageControl 

def start_simple_server(buildsdir, port = 4711, allow_ips = ["127.0.0.1"], params = {})
  web_port = params[:WebPort] || 8080
  @hub = Hub.new

  host_verifier = HostVerifier.new(allow_ips)
  @socket_trigger = SocketTrigger.new(@hub, port, host_verifier).start

  xmlrpc_servlet = XMLRPC::WEBrickServlet.new
  XMLRPCTrigger.new(xmlrpc_servlet, @hub)

  scheduler = BuildScheduler.new(@hub)
  scheduler.add_executor(BuildExecutor.new(@hub, buildsdir))
  scheduler.start

  httpserver = WEBrick::HTTPServer.new(:Port => web_port, :RequestHandler => HostVerifyingHandler.new(host_verifier))
  httpserver.mount("/RPC2", xmlrpc_servlet)
  httpserver.mount("/xmlrpc", xmlrpc_servlet)
  at_exit { httpserver.shutdown }
  Thread.new { httpserver.start }
end

if __FILE__ == $0
  start_simple_server("build")
  @socket_trigger.join
end
