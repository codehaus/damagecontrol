require 'xmlrpc/server'
require 'damagecontrol/Build'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/HubTestHelper'

module DamageControl

  class XMLRPCTrigger
    INTERFACE = XMLRPC::interface("build") {
      meth 'string request(string)', '(DEPRECATED) Request a build, passing in YAML config, returns status info', 'request'
      meth 'string request_build(string,string)', 'Request a build, passing in project_name and scm_timestamp, returns status info', 'request_build'
    }

    # TODO: we should separate the XML-RPC stuff from the dcroot stuff.
    def initialize(xmlrpc_server, channel, dcroot=ENV['DAMAGECONTROL_HOME'])
      if(dcroot.nil?)
        raise "dcroot not specified. specify it explicitly or define the DAMAGECONTROL_HOME env var."
      end
      File.mkpath(dcroot)
    
      xmlrpc_server.add_handler(INTERFACE, self)
      @channel = channel
      @dcroot = dcroot
      @build_bootstrapper = BuildBootstrapper.new
    end

    # deprecated
    def request(build_yaml)
      build = @build_bootstrapper.create_build(build_yaml)
      build.status = Build::QUEUED
      @channel.publish_message(BuildRequestEvent.new(build))
      "DamageControl got your message!"
    end

    def request_build(project_name, scm_timestamp_iso_8601)
      # "%Y-%m-%dT%H:%M:%S"
      # 2004-04-15T18:05:47
      # 0123456789012345678 (index)
      scm_timestamp_utc = Time.utc(
        scm_timestamp_iso_8601[0..3], # year 
        scm_timestamp_iso_8601[5..6], # month
        scm_timestamp_iso_8601[8..9], # day
        scm_timestamp_iso_8601[11..12], # hour
        scm_timestamp_iso_8601[14..15], # minute
        scm_timestamp_iso_8601[17..18] # second
      )
      
      f = project_file(project_name)
      conf = f.read
      build = @build_bootstrapper.create_build(conf)
      # Overwrite the (incorrect) timestamp set by build_bootstrapper.create_build
      build.timestamp = scm_timestamp_utc
            
      build.status = Build::QUEUED
      @channel.publish_message(BuildRequestEvent.new(build))
      "Build has been requested for #{project_name}"
    end
    
    def project_file(project_name)
      path = "#{@dcroot}/projects/#{project_name}/project.yaml"
      if(!File.exists?(path))
        raise "No DamageControl project definition has been created in #{path}"
      end
      File.new("#{path}")
    end
  end

end
