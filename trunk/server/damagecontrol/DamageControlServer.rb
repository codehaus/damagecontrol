#!/usr/bin/env ruby

require 'xmlrpc/server'
require 'webrick'
 
require 'damagecontrol/Version'
require 'damagecontrol/core/Hub'
require 'damagecontrol/core/BuildExecutor'
require 'damagecontrol/core/BuildScheduler'
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
require 'damagecontrol/web/DashboardServlet'

module DamageControl

  class WarningServer
    def start
      @t = Thread.new do
        begin
          @server = TCPServer.new(4711)          
          while (socket = @server.accept)
            socket.print("WARNING WARNING WARNING WARNING\r\n")
            socket.print("DamageControl does not support trigging over port 4711 anymore\r\n")
            socket.print("DamageControlled projects are now configured\r\n")
            socket.print("via http://builds.codehaus.org/private/dashboard\r\n")
            socket.print("Contact Jon or Aslak on #codehaus on irc.codehaus.org or\r\n")
            socket.print("jon@tirsen.com or aslak@thoughtworks.net\r\n")
            socket.print("to get a password so you can reconfigure your project.\r\n")
            socket.print("Sorry for the inconvenience.\r\n")
          end
        rescue => e
        ensure
          puts "Stopped SocketTrigger listening on port #{port}"
        end
      end
    end
    
    def shutdown
      begin
        @server.shutdown
      rescue => e
      end
      begin
        @t.kill
      rescue => e
      end
    end
  end

  class DamageControlServer
    include FileUtils
    include Logging
  
    attr_reader :params
    attr_reader :components
    
    def initialize(params={})
      @params = params
      @components = []
      @project_directories = ProjectDirectories.new(rootdir)
    end
    
    def startup_time
      @startup_time = Time.now if @startup_time.nil?
      @startup_time
    end
  
    def startup_message
      message = "Starting #{DamageControl::VERSION_TEXT} at #{startup_time}, root directory = #{rootdir.inspect}, config = #{params.inspect}"
      root_logger.info(message)
    end
    
    def component(name, instance)
      self.class.module_eval("attr_accessor :#{name}")
      self.send("#{name}=", instance)
      components << instance
    end
    
    def rootdir
      params[:RootDir] || damagecontrol_home
    end
    
    def checkoutdir
      "#{rootdir}/checkout"
    end
    
    def logdir
      "#{rootdir}/log"
    end
    
    def allow_ips
      params[:AllowIPs] || nil
    end
    
    def http_port 
      params[:HttpPort] || 4712
    end
    
    def https_port
      params[:HttpsPort] || 4713
    end
    
    def init_config_services
      component(:hub, Hub.new)
      
      component(:project_directories, @project_directories)
      component(:project_config_repository, ProjectConfigRepository.new(project_directories))
      component(:build_history_repository, BuildHistoryRepository.new(hub, "#{rootdir}/build_history.yaml"))
    end
    
    def init_components
      init_config_services
      
      component(:warning_server, WarningServer.new())
      component(:log_writer, LogWriter.new(hub, @project_directories))
      component(:host_verifier, if allow_ips.nil? then OpenHostVerifier.new else HostVerifier.new(allow_ips) end)
      
      init_build_scheduler
      init_webserver
      init_custom_components
    end
    
    def init_webserver
      component(:httpd, WEBrick::HTTPServer.new(
        :Port => http_port, 
        :RequestHandler => HostVerifyingHandler.new(host_verifier)
      ))
      
      init_public_web
      init_private_web
    end
    
    def init_public_web
      public_xmlrpc_servlet = ::XMLRPC::WEBrickServlet.new
      DamageControl::XMLRPC::StatusPublisher.new(public_xmlrpc_servlet, build_history_repository)
      DamageControl::XMLRPC::ConnectionTester.new(public_xmlrpc_servlet)
      # For public unauthenticated XML-RPC connections like getting status
      httpd.mount("/public/xmlrpc", public_xmlrpc_servlet)
      
      httpd.mount("/public/dashboard", DashboardServlet.new(build_history_repository, project_config_repository, build_scheduler, :public))
      httpd.mount("/public/project", ProjectServlet.new(build_history_repository, nil, nil, :public))
      
      httpd.mount("/public/images", WEBrick::HTTPServlet::FileHandler, "#{webdir}/images")
      httpd.mount("/public/css", WEBrick::HTTPServlet::FileHandler, "#{webdir}/css")
    end
    
    def init_private_web
      private_xmlrpc_servlet = ::XMLRPC::WEBrickServlet.new
      DamageControl::XMLRPC::ServerControl.new(private_xmlrpc_servlet)
      component(:trigger, DamageControl::XMLRPC::Trigger.new(private_xmlrpc_servlet, @hub, project_config_repository))
      # For private authenticated and encrypted (with eg an Apache proxy) XML-RPC connections like triggering a build
      httpd.mount("/private/xmlrpc", private_xmlrpc_servlet)

      httpd.mount("/private/dashboard", DashboardServlet.new(build_history_repository, project_config_repository, build_scheduler, :private))
      httpd.mount("/private/project", ProjectServlet.new(build_history_repository, project_config_repository, trigger, :private))
      
      httpd.mount("/private/images", WEBrick::HTTPServlet::FileHandler, "#{webdir}/images")
      httpd.mount("/private/css", WEBrick::HTTPServlet::FileHandler, "#{webdir}/css")
    end
    
    def webdir
      "#{damagecontrol_home}/server/damagecontrol/web"
    end
    
    def checkoutdir
      "#{rootdir}/checkout"
    end
    
    def init_build_scheduler
      component(:build_scheduler, BuildScheduler.new(hub))
      init_build_executors
    end
    
    def init_build_executors
      # Only use one build executor (don't allow parallel builds)
      build_scheduler.add_executor(BuildExecutor.new(hub, build_history_repository, project_directories))
    end
    
    def init_custom_components
    end
    
    def log4r_config_file
      "#{rootdir}/log4r.xml"
    end
    
    def init_logging
      puts log4r_config_file.tainted?
      if File.exists?(log4r_config_file)
        Logging.init_logging(log4r_config_file, { 
            'rootdir' => rootdir,
            'logdir' => mkdir_p(logdir),
            'damagecontrol_home' => damagecontrol_home
        })
      else
        Logging.quiet
      end
    end
    
    def start
      init_logging
      
      startup_message
      init_components

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
      httpd.shutdown
      
      # this stuff doesn't work for some reason :-(
      components.each do |component|
        begin
          if(component.respond_to?(:shutdown))
            # shut down components in a separate thread
            Thread.new do
              logger.info("shutting down #{component}")
              component.shutdown 
            end
          end
        rescue Exception => e
          logger.error("could not shut down #{component}: #{format_exception(e)}")
        end
      end
    end
  end
end

if __FILE__ == $0
  DamageControl::DamageControlServer.new.start.wait_for_shutdown
end
