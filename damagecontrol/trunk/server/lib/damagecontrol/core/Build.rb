require 'damagecontrol/core/BuildEvents'
require 'pebbles/Matchable'
require 'pebbles/TimeUtils'
require 'xmlrpc/utils'
require 'rexml/document'
require 'cgi'
require 'rubygems'
require 'rscm'

module DamageControl

  class Build
    include XMLRPC::Marshallable
    include Pebbles::Matchable

    IDLE                   = "IDLE"
    QUEUED                 = "QUEUED"
    DETERMINING_CHANGESETS = "DETERMINING CHANGESETS"
    CHECKING_OUT           = "CHECKING OUT"
    BUILDING               = "BUILDING"
    SUCCESSFUL             = "SUCCESSFUL"
    FAILED                 = "FAILED"
    KILLED                 = "KILLED"

    attr_accessor :project_name
    attr_accessor :config
    attr_accessor :changesets
    attr_accessor :label
    # error_message can go - it is redundant to what goes in stderr log. and it is never accessed
    attr_accessor :error_message
    attr_accessor :status

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

    def url
      # FIXME: this member is ugly - rather pass something into the populate method
      @html_url.nil? ? nil : "#{@html_url}public/project/#{CGI.escape(project_name)}?dc_creation_time=#{dc_creation_time.ymdHMS}"
    end
    
    def initialize(project_name = nil, config={}, html_url=nil)
      @project_name = project_name
      @config = config
      @status = IDLE
      @changesets = RSCM::ChangeSets.new
      @html_url = html_url
    end
    
    def build_command_line
      config["build_command_line"]
    end

    def quiet_period
      if config["quiet_period"].nil? then nil else config["quiet_period"].to_i end
    end

    # Populates an RSS item
    # Also see the native RSS support in RSCM::ChangeSets which is somewhat similar, but with slightly
    # different content.
    def populate(rss_item, message_linker, change_linker)
      label_text = if successful? then "##{label} " else "" end
      title = "#{project_name}: Build #{label_text}#{status}"

      rss_item.pubDate = dc_creation_time
      rss_item.author = changesets.developers.join(", ")
      rss_item.title = title
      rss_item.link = url # YUK - pass in to this method instead
      rss_item.description = ""

      if(!changesets.empty?)
        changesets.each do |changeset|
          rss_item.description << "<b>#{changeset.developer}</b><br/>\n"
          rss_item.description << message_linker.highlight(changeset.message).gsub(/\n/, "<br/>\n") << "<p/>\n"
          changeset.each do |change|
            rss_item.description << change_linker.change_url(change, true) << "<br/>\n"
          end
          rss_item.description << "<hr/>\n"
        end
      else
        rss_item.description = "No changes in this build (since the last build)"
      end
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
    
    def changesets=(changesets)
      raise "changesets must be of type #{ChangeSets.name} - was #{changesets.class.name}" unless changesets.is_a?(::RSCM::ChangeSets)
      @changesets = changesets
    end

    def __get_instance_variables
      (instance_variables.reject {|var| var == "@html_url"}).collect {|var| [var[1..-1], eval(var)] }
    end

  end
end

