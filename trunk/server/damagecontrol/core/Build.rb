require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/scm/Changes'
require 'pebbles/Matchable'
require 'pebbles/TimeUtils'
require 'xmlrpc/utils'
require 'rexml/document'
require 'cl/xmlserial'

module DamageControl

  class Build
    include XMLRPC::Marshallable
    include XmlSerialization
    include Pebbles::Matchable

    IDLE = "IDLE"
    SUCCESSFUL = "SUCCESSFUL"
    FAILED = "FAILED"
    QUEUED = "QUEUED"
    BUILDING = "BUILDING"
    KILLED = "KILLED"
    DETERMINING_CHANGESETS = "DETERMINING CHANGESETS"
    CHECKING_OUT = "CHECKING OUT"

    attr_accessor :project_name
    attr_accessor :config
    attr_accessor :changesets
    attr_accessor :label
    # This can go - it is redundant to what goes in stderr log. and it is never accessed
    attr_accessor :error_message
    attr_accessor :status

#START FIXME - not portable data
    attr_accessor :url
    attr_accessor :archive_dir
#END FIXME

    # the scm to use to talk to this builds source control system
    attr_accessor :scm
    
    # The timestamp of the last commit that went into this build.
    # This timestamp should be in UTC according to the SCM machine.
    attr_accessor :scm_commit_time

    # The timestamp when the build started.
    # This timestamp should be in UTC according to the DC machine.
    # It is used to estimate remaining time for the progress bar
    # DON'T USE THIS TO IDENTIFY/LOOK UP BUILDS
    attr_accessor :dc_start_time
    
    # The timestamp when the build was created.
    # This is typically before the dc_start_time, as a build may 
    # live in a build queue for a while
    # USE THIS TO IDENTIFY/LOOK UP BUILDS
    # This timestamp should be in UTC according to the DC machine.
    attr_accessor :dc_creation_time

    # Build duration in seconds. Should be set when the build is complete
    attr_accessor :duration 

    attr_accessor :potential_label
    
    def dc_end_time
      dc_start_time + duration if duration
    end

    def completed?
      status == SUCCESSFUL || status == FAILED || status == KILLED
    end
    
    def queued?
      status == QUEUED
    end
    
    def successful?
      status == SUCCESSFUL
    end
    
    def failed?
      status == FAILED
    end
    
    def initialize(project_name = nil, config={})
      @project_name = project_name
      @config = config
      @status = IDLE
      @changesets = ChangeSets.new
    end
    
    def build_command_line
      config["build_command_line"]
    end

    def quiet_period
      if config["quiet_period"].nil? then nil else config["quiet_period"].to_i end
    end

    def to_rss_item
      item = REXML::Element.new("item")
      label_text = if successful? then "##{label} " else "" end
      title = "#{project_name}: Build #{label_text}#{status.downcase}"
      item.add_element("title").add_text(title)
      item.add_element("link").add_text(url)
      item.add_element("pubDate").add_text(dc_creation_time.to_rfc2822)
      item.add_element("description").add_text(changesets.to_rss_description.to_s())
      item
    end

    def ==(o)
      return false unless o.is_a? Build
      project_name == o.project_name &&
      status == o.status &&
      label == o.label&&
      config == o.config &&
      dc_creation_time == o.dc_creation_time &&
      changesets == o.changesets
    end

  end
end

