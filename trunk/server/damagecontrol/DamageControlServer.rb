#!/usr/bin/env ruby

require 'xmlrpc/server'
require 'webrick'
 
require 'damagecontrol/Version'
require 'damagecontrol/core/Hub'
require 'damagecontrol/core/BuildExecutor'
require 'damagecontrol/core/BuildScheduler'
require 'damagecontrol/core/SocketTrigger'
require 'damagecontrol/core/HostVerifyingHandler'
require 'damagecontrol/core/LogWriter'
require 'damagecontrol/xmlrpc/Trigger'
require 'damagecontrol/core/BuildHistoryRepository'
require 'damagecontrol/core/ProjectConfigRepository'
require 'damagecontrol/xmlrpc/StatusPublisher'
require 'damagecontrol/xmlrpc/ConnectionTester'
require 'damagecontrol/xmlrpc/ServerControl'
require 'damagecontrol/core/HostVerifier'
require 'damagecontrol/web/ProjectServlet'

module DamageControl
  class DamageControlServer
    include FileUtils
  
    attr_reader :params
    attr_reader :components
    
    def initialize(params={})
      @params = params
      @components = []
      create_components
    end
  
    def startup_message
      message = "Starting #{DamageControl::VERSION_TEXT} at #{Time.now}"
      puts message
      Logging.logger.info(message)
    end
    
    def component(name, instance)
      self.class.module_eval("attr_accessor :#{name}")
      self.send("#{name}=", instance)
      components << instance
    end
    
    def create_components
      Logging.quiet

      rootdir = params[:RootDir] || damagecontrol_home
      allow_ips = params[:AllowIPs] || nil 
      port = params[:SocketTriggerPort] || 4711
      http_port = params[:HttpPort] || 4712
      https_port = params[:HttpsPort] || 4713
    
      logdir = "#{rootdir}/log"
      checkoutdir = "#{rootdir}/checkout"
      
      @hub = Hub.new
      LogWriter.new(@hub, logdir)
    
      host_verifier = if allow_ips.nil? then OpenHostVerifier.new else HostVerifier.new(allow_ips) end
      @socket_trigger = SocketTrigger.new(@hub, port, host_verifier)
    
      public_xmlrpc_servlet = ::XMLRPC::WEBrickServlet.new
      private_xmlrpc_servlet = ::XMLRPC::WEBrickServlet.new
      
      component(:project_directories, ProjectDirectories.new(rootdir))
      component(:project_config_repository, ProjectConfigRepository.new(project_directories))
      
      component(:trigger, DamageControl::XMLRPC::Trigger.new(private_xmlrpc_servlet, @hub, project_config_repository))
    
      component(:build_history_repository, BuildHistoryRepository.new(@hub, "#{rootdir}/build_history.yaml"))
      
      DamageControl::XMLRPC::StatusPublisher.new(public_xmlrpc_servlet, build_history_repository)
      DamageControl::XMLRPC::ServerControl.new(private_xmlrpc_servlet)
      DamageControl::XMLRPC::ConnectionTester.new(public_xmlrpc_servlet)
      
      scheduler = BuildScheduler.new(@hub)
      # Only use one build executor (don't allow parallel builds)
      scheduler.add_executor(BuildExecutor.new(@hub, build_history_repository, checkoutdir))
    
      component(:httpd, WEBrick::HTTPServer.new(
        :Port => http_port, 
        :RequestHandler => HostVerifyingHandler.new(host_verifier)
      ))
      
      # For public unauthenticated XML-RPC connections like getting status
      httpd.mount("/public/xmlrpc", public_xmlrpc_servlet)
      # For private authenticated and encrypted (with eg an Apache proxy) XML-RPC connections like triggering a build
      httpd.mount("/private/xmlrpc", private_xmlrpc_servlet)

      httpd.mount("/private/admin", ProjectServlet.new(build_history_repository, project_config_repository, trigger))
    end
      
    def start
      startup_message

      at_exit { shutdown }
      @threads = []
      components.each do |component|
        @threads << Thread.new { component.start } if(component.respond_to?(:start))
      end
      
      self
    end

    def wait_for_shutdown
      @threads.each {|thread| thread.join }
    end
    
    def shutdown
      components.each do |component|
        component.shutdown if(component.respond_to?(:shutdown))
      end
    end
  end
end

if __FILE__ == $0
  DamageControl::DamageControlServer.new.start.wait_for_shutdown
end
