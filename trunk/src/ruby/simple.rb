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
require 'damagecontrol/LogWriter'
require 'damagecontrol/xmlrpc/Trigger'
require 'damagecontrol/BuildHistoryRepository'
require 'damagecontrol/xmlrpc/StatusPublisher'
require 'damagecontrol/xmlrpc/ConnectionTester'

include DamageControl 

Logging.quiet

def start_simple_server(params = {})
  rootdir = params[:RootDir] || File.expand_path(".")
  allow_ips = params[:AllowIPs] || ["127.0.0.1"]
  port = params[:SocketTriggerPort] || 4711
  http_port = params[:HttpPort] || 4712
  https_port = params[:HttpsPort] || 4713

  logdir = "#{rootdir}/log"
  checkoutdir = "#{rootdir}/checkout"

  @hub = Hub.new
  LogWriter.new(@hub, logdir)

  host_verifier = HostVerifier.new(allow_ips)
  @socket_trigger = SocketTrigger.new(@hub, port, host_verifier).start

  public_xmlrpc_servlet = XMLRPC::WEBrickServlet.new
  private_xmlrpc_servlet = XMLRPC::WEBrickServlet.new

  DamageControl::XMLRPC::Trigger.new(private_xmlrpc_servlet, @hub)

  @build_history_repository = BuildHistoryRepository.new(@hub, "build_history.yaml")
  @build_history_repository.start
  DamageControl::XMLRPC::StatusPublisher.new(public_xmlrpc_servlet, @build_history_repository)
  
  DamageControl::XMLRPC::ConnectionTester.new(public_xmlrpc_servlet)
  
  scheduler = BuildScheduler.new(@hub)
  # Only use one build executor (don't allow parallel builds)
  scheduler.add_executor(BuildExecutor.new(@hub, @build_history_repository, checkoutdir))
  scheduler.start

  httpd = WEBrick::HTTPServer.new(
    :Port => http_port, 
    :RequestHandler => HostVerifyingHandler.new(host_verifier)
  )
  
  # For public unauthenticated XML-RPC connections like getting status
  httpd.mount("/public/xmlrpc", public_xmlrpc_servlet)
  # For private authenticated and encrypted (with eg an Apache proxy) XML-RPC connections like triggering a build
  httpd.mount("/private/xmlrpc", private_xmlrpc_servlet)
  
  at_exit { httpd.shutdown }
  Thread.new { httpd.start }

end

if __FILE__ == $0
  start_simple_server(
    :BuildsDir => "checkout", 
    :LogsDir => "log", 
    :SocketTriggerPort => 4711, 
    :HttpPort => 4712,
    :AllowIPs => ["127.0.0.1", "64.7.141.17", "66.216.68.111", "81.5.134.59", "217.158.24.17" ])
    
  @socket_trigger.join
end
