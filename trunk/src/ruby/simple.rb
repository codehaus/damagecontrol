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
require 'damagecontrol/publisher/XMLRPCStatusPublisher'

include DamageControl 

def start_simple_server(params = {})
  logsdir = params[:LogsDir] || File.expand_path("log")
  buildsdir = params[:BuildsDir] || File.expand_path("build")
  allow_ips = params[:AllowIPs] || ["127.0.0.1"]
  port = params[:SocketTriggerPort] || 4711
  http_port = params[:HttpPort] || 4712
  https_port = params[:HttpsPort] || 4713

  @hub = Hub.new
  LogWriter.new(@hub, logsdir)

  host_verifier = HostVerifier.new(allow_ips)
  @socket_trigger = SocketTrigger.new(@hub, port, host_verifier).start

  query_servlet = XMLRPC::WEBrickServlet.new

  XMLRPCTrigger.new(query_servlet, @hub)

  bhp = BuildHistoryPublisher.new(@hub, "build_history.yaml")
  bhp.start
  XMLRPCStatusPublisher.new(query_servlet, bhp)
  
  scheduler = BuildScheduler.new(@hub)
  # Only use one build executor (don't allow parallel builds)
  scheduler.add_executor(BuildExecutor.new(@hub, buildsdir))
  scheduler.start

  # For unsecure XML-RPC connections like getting status
  httpd = WEBrick::HTTPServer.new(
    :Port => http_port, 
    :RequestHandler => HostVerifyingHandler.new(host_verifier)
  )
  httpd.mount("/xmlrpc", query_servlet)
  at_exit { httpd.shutdown }
  Thread.new { httpd.start }

=begin
  # For secure XML-RPC connections like registering new projects and requesting builds
  require "webrick/https"
  httpsd = WEBrick::HTTPServer.new(
    :Port           => https_port,
    :SSLEnable      => true,
    :SSLPrivateKey  => OpenSSL::PKey::RSA.new(File::read("damagecontrol.key")),
    :SSLCertificate => OpenSSL::X509::Certificate.new(File::read("damagecontrol.crt"))
  )
  at_exit { httpsd.shutdown }
  Thread.new { httpsd.start }
=end

end

if __FILE__ == $0
  start_simple_server("build")
  @socket_trigger.join
end
