#!/usr/bin/env ruby

$damagecontrol_home = File.expand_path("#{File.dirname(__FILE__)}/../..")

require 'xmlrpc/server'
require 'socket'
require 'webrick'
 
require 'pebbles/Space'
require 'damagecontrol/Version'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildExecutor'
require 'damagecontrol/core/BuildScheduler'
require 'damagecontrol/core/DependentBuildTrigger'
require 'damagecontrol/core/FixedTimeScheduler'
require 'damagecontrol/core/SCMPoller'
require 'damagecontrol/core/HostVerifyingHandler'
require 'damagecontrol/core/LogWriter'
require 'damagecontrol/core/LogMerger'
require 'damagecontrol/core/ArtifactArchiver'
require 'damagecontrol/core/BuildHistoryRepository'
require 'damagecontrol/core/ProjectConfigRepository'
require 'damagecontrol/core/HostVerifier'
require 'damagecontrol/web/ProjectServlet'
require 'damagecontrol/web/InstallTriggerServlet'
require 'damagecontrol/web/ConfigureProjectServlet'
require 'damagecontrol/web/SearchServlet'
require 'damagecontrol/web/DashboardServlet'
require 'damagecontrol/web/StatusImageServlet'
require 'damagecontrol/web/LogFileServlet'
require 'damagecontrol/web/RssServlet'
require 'damagecontrol/xmlrpc/Trigger'
require 'damagecontrol/xmlrpc/StatusPublisher'
require 'damagecontrol/xmlrpc/ConnectionTester'
require 'damagecontrol/xmlrpc/ServerControl'

require 'damagecontrol/scm/CVSWebConfigurator'
require 'damagecontrol/scm/SVNWebConfigurator'
require 'damagecontrol/scm/NoSCMWebConfigurator'

require 'damagecontrol/scm/JiraWebConfigurator'
require 'damagecontrol/scm/ScarabWebConfigurator'
require 'damagecontrol/scm/RubyForgeTrackerWebConfigurator'
require 'damagecontrol/scm/SourceForgeTrackerWebConfigurator'
require 'damagecontrol/scm/NoTrackerWebConfigurator'
require 'damagecontrol/scm/BugzillaWebConfigurator'

require 'damagecontrol/web/ConsoleOutputReport'
require 'damagecontrol/web/BuildArtifactsReport'
require 'damagecontrol/web/ChangesReport'
require 'damagecontrol/web/ErrorsReport'
require 'damagecontrol/web/cruisecontrol/TestsReport'

# patch webrick so that it displays files it doesn't recognize as text
# TODO: add svg MIME type so IE can display generated SVGs - http://www.pinkjuice.com/svg/mime.xhtml
module WEBrick
  module HTTPUtils
    def mime_type(filename, mime_tab)
      if suffix = (/\.(\w+)$/ =~ filename && $1)
        mime_tab["svg"] = "image/svg+xml"
        mtype = mime_tab[suffix.downcase]
      end
      mtype || "text/plain"
    end
    module_function :mime_type
  end
end

module DamageControl

  class DamageControlServer
    include FileUtils
    include Logging
  
    attr_reader :params
    attr_reader :components
    
    def initialize(params={})
      @params = params
      @components = []
    end
    
    def startup_time
      @startup_time = Time.now if @startup_time.nil?
      @startup_time
    end
    
    def ruby_version
      require 'rbconfig.rb'
      "ruby #{Config::CONFIG['MAJOR']}.#{Config::CONFIG['MINOR']}.#{Config::CONFIG['TEENY']} #{Config::CONFIG['host']}"
    end
  
    def startup_message
      message = "Starting #{DamageControl::VERSION_TEXT} at #{startup_time}, ruby version = #{ruby_version}, root directory = #{rootdir.inspect}, damagecontrol home = #{damagecontrol_home.inspect}, config = #{params.inspect}"
      root_logger.info(message)
    end
    
    def component(name, instance)
      self.class.module_eval("attr_accessor :#{name}")
      self.send("#{name}=", instance)
      components << instance
    end
    
    def rootdir
      params[:RootDir] || "#{damagecontrol_home}/work"
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
    
    def web_url
      url = params[:ExternalWebUrl] || "http://#{get_ip}:#{http_port}/"
      ensure_trailing_slash(url)
    end
    
    def trig_xmlrpc_url
      params[:TrigXmlrpcUrl] || "#{web_url}private/xmlrpc"
    end
    
    def public_web_url
      url = params[:PublicWebUrl] || "#{web_url}public/"
      ensure_trailing_slash(url)
    end
    
    def get_ip
      IPSocket.getaddress(Socket.gethostname)
    end
    
    def init_config_services
      component(:hub, Pebbles::MulticastSpace.new)
      
      component(:project_directories, ProjectDirectories.new(rootdir))
      component(:project_config_repository, ProjectConfigRepository.new(project_directories, public_web_url))
      component(:build_history_repository, BuildHistoryRepository.new(hub, project_directories, BuildSerializer.new(web_url)))

      # Let's keep this, but empty/modify method bodies as necessary between releases.
      project_config_repository.upgrade_all
# THIS SEEMS TO TOTALLY MESS UP THE YAMLs - either a yaml bug or we're not opening/closing changesets.yaml files properly.
# Grab some yamls from BuildSerializerTest - stick in a DC installation and try it out to debug this. (AH)
# build_history_repository.upgrade_all
    end
    
    def init_components
      init_config_services
      
      component(:host_verifier, if allow_ips.nil? then OpenHostVerifier.new else HostVerifier.new(allow_ips) end)
      
      init_build_scheduler
      init_scm_poller
      init_fixed_time_scheduler
      init_webserver
      init_custom_components
      init_build_history_stats_publisher
    end
    
    def access_log
      return $stderr unless params[:AccessLog]
      File.open(params[:AccessLog], "w+")
    end
    
    def init_webserver
      component(:httpd, WEBrick::HTTPServer.new(
        :Port => http_port, 
        :RequestHandler => HostVerifyingHandler.new(host_verifier),
        :AccessLog => [
          [ access_log, WEBrick::AccessLog::COMMON_LOG_FORMAT ],
          [ access_log, WEBrick::AccessLog::REFERER_LOG_FORMAT ]
        ]
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
      
      httpd.mount("/public/dashboard", DashboardServlet.new(:public, build_scheduler, build_history_repository, project_config_repository, project_directories))
      httpd.mount("/public/project", ProjectServlet.new(:public, build_scheduler, build_history_repository, project_config_repository, project_directories, nil, report_classes, public_web_url + "rss", trig_xmlrpc_url))
      httpd.mount("/public/search", SearchServlet.new(build_history_repository))
      httpd.mount("/public/log", LogFileServlet.new(:public, build_scheduler, build_history_repository, project_config_repository, project_directories))
      httpd.mount("/public/root", indexing_file_handler)
      httpd.mount("/public/rss", RssServlet.new(build_history_repository, public_web_url + "project/"))
      
# TODO: simplify this!!!!!!
      httpd.mount("/public/images", WEBrick::HTTPServlet::FileHandler, "#{webdir}/images")
      httpd.mount("/public/project/images", WEBrick::HTTPServlet::FileHandler, "#{webdir}/images")
      httpd.mount("/public/search/images", WEBrick::HTTPServlet::FileHandler, "#{webdir}/images")
      httpd.mount("/public/largeicons", WEBrick::HTTPServlet::FileHandler, "#{webdir}/icons/24x24/plain")
      httpd.mount("/public/project/largeicons", WEBrick::HTTPServlet::FileHandler, "#{webdir}/icons/24x24/plain")
      httpd.mount("/public/search/largeicons", WEBrick::HTTPServlet::FileHandler, "#{webdir}/icons/24x24/plain")
      httpd.mount("/public/smallicons", WEBrick::HTTPServlet::FileHandler, "#{webdir}/icons/16x16/plain")
      httpd.mount("/public/project/smallicons", WEBrick::HTTPServlet::FileHandler, "#{webdir}/icons/16x16/plain")
      httpd.mount("/public/search/smallicons", WEBrick::HTTPServlet::FileHandler, "#{webdir}/icons/16x16/plain")
      httpd.mount("/public/images/currentstatus", CurrentStatusImageServlet.new(build_history_repository, build_scheduler))
      httpd.mount("/public/images/lastcompletedstatus", LastCompletedImageServlet.new(build_history_repository, build_scheduler))
      httpd.mount("/public/images/timestampstatus", TimestampImageServlet.new(build_history_repository, build_scheduler))
      httpd.mount("/public/css", WEBrick::HTTPServlet::FileHandler, "#{webdir}/css")
      httpd.mount("/public/project/css", WEBrick::HTTPServlet::FileHandler, "#{webdir}/css")
      httpd.mount("/public/search/css", WEBrick::HTTPServlet::FileHandler, "#{webdir}/css")
      
      httpd.mount("/favicon.ico", WEBrick::HTTPServlet::FileHandler, "#{webdir}/icons/ico/damagecontrol-icon-square.ico")
    end
    
    def indexing_file_handler
      fh = WEBrick::HTTPServlet::FileHandler.new(httpd, rootdir, :FancyIndexing => true)
      # <HACK>
      # patch it to show directories even if there's a index.html in the directory
      fh.instance_eval("@config = @config.dup")
      fh.instance_eval("@config[:DirectoryIndex] = []")
      def fh.get_instance(*args)
        self
      end
      # </HACK>
      fh
    end
    
    def init_private_web
      private_xmlrpc_servlet = ::XMLRPC::WEBrickServlet.new
      DamageControl::XMLRPC::StatusPublisher.new(private_xmlrpc_servlet, build_history_repository)
      DamageControl::XMLRPC::ConnectionTester.new(private_xmlrpc_servlet)
      DamageControl::XMLRPC::ServerControl.new(private_xmlrpc_servlet, hub)
      component(:trigger, DamageControl::XMLRPC::Trigger.new(private_xmlrpc_servlet, @hub, project_config_repository, public_web_url))
      # For private authenticated and encrypted (with eg an Apache proxy) XML-RPC connections like triggering a build
      httpd.mount("/private/xmlrpc", private_xmlrpc_servlet)

      httpd.mount("/private/dashboard", DashboardServlet.new(:private, build_scheduler, build_history_repository, project_config_repository, project_directories))
      httpd.mount("/private/project", ProjectServlet.new(:private, build_scheduler, build_history_repository, project_config_repository, project_directories, trigger, report_classes, public_web_url + "rss", trig_xmlrpc_url))
      httpd.mount("/private/install_trigger", InstallTriggerServlet.new(project_config_repository, trig_xmlrpc_url))
      httpd.mount("/private/configure", ConfigureProjectServlet.new(project_config_repository, scm_configurator_classes, tracking_configurator_classes, trig_xmlrpc_url))
      httpd.mount("/private/search", SearchServlet.new(build_history_repository))
      httpd.mount("/private/log", LogFileServlet.new(:private, build_scheduler, build_history_repository, project_config_repository, project_directories))
      httpd.mount("/private/root", indexing_file_handler)
      
# TODO: simplify this!!!!!! (Rails to the rescue soon)
      httpd.mount("/private/images", WEBrick::HTTPServlet::FileHandler, "#{webdir}/images")
      httpd.mount("/private/project/images", WEBrick::HTTPServlet::FileHandler, "#{webdir}/images")
      httpd.mount("/private/configure/images", WEBrick::HTTPServlet::FileHandler, "#{webdir}/images")
      httpd.mount("/private/install_trigger/images", WEBrick::HTTPServlet::FileHandler, "#{webdir}/images")
      httpd.mount("/private/search/images", WEBrick::HTTPServlet::FileHandler, "#{webdir}/images")
      httpd.mount("/private/largeicons", WEBrick::HTTPServlet::FileHandler, "#{webdir}/icons/24x24/plain")
      httpd.mount("/private/project/largeicons", WEBrick::HTTPServlet::FileHandler, "#{webdir}/icons/24x24/plain")
      httpd.mount("/private/configure/largeicons", WEBrick::HTTPServlet::FileHandler, "#{webdir}/icons/24x24/plain")
      httpd.mount("/private/install_trigger/largeicons", WEBrick::HTTPServlet::FileHandler, "#{webdir}/icons/24x24/plain")
      httpd.mount("/private/search/largeicons", WEBrick::HTTPServlet::FileHandler, "#{webdir}/icons/24x24/plain")
      httpd.mount("/private/smallicons", WEBrick::HTTPServlet::FileHandler, "#{webdir}/icons/16x16/plain")
      httpd.mount("/private/project/smallicons", WEBrick::HTTPServlet::FileHandler, "#{webdir}/icons/16x16/plain")
      httpd.mount("/private/configure/smallicons", WEBrick::HTTPServlet::FileHandler, "#{webdir}/icons/16x16/plain")
      httpd.mount("/private/install_trigger/smallicons", WEBrick::HTTPServlet::FileHandler, "#{webdir}/icons/16x16/plain")
      httpd.mount("/private/search/smallicons", WEBrick::HTTPServlet::FileHandler, "#{webdir}/icons/16x16/plain")
      
      httpd.mount("/private/images/currentstatus", CurrentStatusImageServlet.new(build_history_repository, build_scheduler))
      httpd.mount("/private/images/lastcompletedstatus", LastCompletedImageServlet.new(build_history_repository, build_scheduler))
      httpd.mount("/private/images/timestampstatus", TimestampImageServlet.new(build_history_repository, build_scheduler))
      httpd.mount("/private/css", WEBrick::HTTPServlet::FileHandler, "#{webdir}/css")
      httpd.mount("/private/project/css", WEBrick::HTTPServlet::FileHandler, "#{webdir}/css")
      httpd.mount("/private/configure/css", WEBrick::HTTPServlet::FileHandler, "#{webdir}/css")
      httpd.mount("/private/install_trigger/css", WEBrick::HTTPServlet::FileHandler, "#{webdir}/css")
      httpd.mount("/private/search/css", WEBrick::HTTPServlet::FileHandler, "#{webdir}/css")
    end
    
    def report_classes
      [
        DamageControl::ChangesReport,
        DamageControl::ConsoleOutputReport,
        DamageControl::ErrorsReport,
        DamageControl::TestsReport,
        DamageControl::BuildArtifactsReport
      ]
    end

    def scm_configurator_classes
      [
        DamageControl::NoSCMWebConfigurator,
        DamageControl::CVSWebConfigurator,
        DamageControl::SVNWebConfigurator
      ]
    end
    
    def tracking_configurator_classes
      [
        DamageControl::NoTrackerWebConfigurator,
        DamageControl::JiraWebConfigurator,
        DamageControl::ScarabWebConfigurator,
        DamageControl::RubyForgeTrackerWebConfigurator,
        DamageControl::SourceForgeTrackerWebConfigurator,
        DamageControl::BugzillaWebConfigurator
      ]
      
    end
    
    def webdir
      "#{damagecontrol_home}/lib/damagecontrol/web"
    end
    
    def init_build_scheduler
      component(:log_writer, LogWriter.new(hub, build_history_repository))
      component(:log_merger, LogMerger.new(hub, build_history_repository))
      component(:artifact_archiver, ArtifactArchiver.new(hub, project_directories))
      component(:dependent_build_trigger, DependentBuildTrigger.new(hub, project_config_repository))
      component(:build_scheduler, BuildScheduler.new(hub))
      init_build_executors
    end
    
    def init_build_executors
      # Only use one build executor (don't allow parallel builds)
      build_scheduler.add_executor(BuildExecutor.new('executor1', hub, project_config_repository, build_history_repository))
    end
    
    def polling_interval
      params[:PollingInterval] || 10 # poll every ten seconds if not specified
    end
    
    def init_scm_poller

      if(polling_interval > 0)
        component(:scm_poller, 
          SCMPoller.new(hub, polling_interval, project_directories, project_config_repository, build_history_repository, build_scheduler))
      end
    end
    
    def init_fixed_time_scheduler
      component(:fixed_time_scheduler, 
        FixedTimeScheduler.new(hub, 10, project_config_repository, build_scheduler))
    end

    def init_custom_components
    end
    
    def init_build_history_stats_publisher
    end
    
    def log4r_config_file
      "#{rootdir}/log4r.xml"
    end
    
    def init_logging
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
      trap("INT") { shutdown }
      trap("TERM") { shutdown }
      @threads = []
      components.each do |component|
        if component.respond_to?(:start)
          thread = Thread.new { component.start }
          thread[:name] = component.to_s()
          @threads << thread
        end
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
  DamageControl::DamageControlServer.new({
    :RootDir => ENV['DAMAGECONTROL_WORK']
  }).start.wait_for_shutdown
end
