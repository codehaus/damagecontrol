#!/usr/bin/env ruby

require 'xmlrpc/server'
require 'webrick'
 
$damagecontrol_home = File::expand_path('../..') 
$:.push("#{$damagecontrol_home}/src/ruby")

require 'damagecontrol/Version'
require 'damagecontrol/core/Hub'
require 'damagecontrol/core/BuildExecutor'
require 'damagecontrol/core/BuildScheduler'
require 'damagecontrol/core/SocketTrigger'
require 'damagecontrol/core/HostVerifyingHandler'
require 'damagecontrol/core/LogWriter'
require 'damagecontrol/xmlrpc/Trigger'
require 'damagecontrol/core/BuildHistoryRepository'
require 'damagecontrol/xmlrpc/StatusPublisher'
require 'damagecontrol/xmlrpc/ConnectionTester'
require 'damagecontrol/core/HostVerifier'

include DamageControl 

Logging.quiet

def startup_message
  message = "Starting #{DamageControl::VERSION_TEXT} at #{Time.now}"
  puts message
  Logging.logger.info(message)
end

def start_simple_server(params = {})
  rootdir = params[:RootDir] || File.expand_path(".")
  allow_ips = params[:AllowIPs] || nil 
  port = params[:SocketTriggerPort] || 4711
  http_port = params[:HttpPort] || 4712
  https_port = params[:HttpsPort] || 4713

  logdir = "#{rootdir}/log"
  checkoutdir = "#{rootdir}/checkout"
  
  startup_message

  @hub = Hub.new
  LogWriter.new(@hub, logdir)

  host_verifier = if allow_ips.nil? then OpenHostVerifier.new else HostVerifier.new(allow_ips) end
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
