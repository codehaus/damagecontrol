require 'damagecontrol/core/BuildEvents'
require 'xmlrpc/utils'

module DamageControl

  class Modification
    def initialize(path="", developer="", message="", revision="", time="")
      self.path, self.developer, self.message, self.revision, self.time = 
        path, developer, message, revision, time
    end
  
    attr_accessor :path
    attr_accessor :developer
    attr_accessor :message
    attr_accessor :revision
    attr_accessor :previous_revision
    # This is an UTC ruby time
    attr_accessor :time
    
    def message=(message)
      raise "can't be null" if message.nil?
      @message = message
    end

    def developer=(developer)
      raise "can't be null" if developer.nil?
      @developer = developer
    end
  end

  class Build
    include XMLRPC::Marshallable

    IDLE           = "IDLE"
    SUCCESSFUL     = "SUCCESSFUL"
    FAILED         = "FAILED"
    QUEUED         = "QUEUED"
    BUILDING       = "BUILDING"
    CHECKING_OUT   = "CHECKING OUT"

    attr_accessor :project_name

    # Time for this build in format:
    # <year><month><day><hour><min><sec>
    # Always in timezone UTC
    attr_accessor :timestamp
    
    attr_accessor :config
    attr_accessor :modification_set
    attr_accessor :label
    attr_accessor :error_message
    attr_accessor :status
    attr_accessor :url

    attr_accessor :start_time
    attr_accessor :end_time
    attr_accessor :potential_label

    def duration_seconds
      return 0 if end_time.nil? || start_time.nil?
      end_time - start_time
    end
    
    def duration_formatted
      "#{duration_seconds / 60}:#{duration_seconds % 60}"
    end
    
    def completed?
      status == SUCCESSFUL || status == FAILED
    end
    
    def successful?
      status == SUCCESSFUL
    end
    
    def initialize(project_name = nil, timestamp = Time.now, config={})
      @project_name = project_name
      @config = config
      @status = IDLE
      @modification_set = []
      self.timestamp = timestamp
    end
    
    def timestamp=(time)
      @timestamp = Build.format_timestamp(time)
    end
    
    def timestamp_as_i
      Build.timestamp_to_i(timestamp)
    end
    
    def timestamp_as_time
      Build.timestamp_to_time(timestamp)
    end
    
    def timestamp_for_humans
      timestamp_as_time.strftime("%d %b %Y %H:%M:%S")
    end
    
    def Build.format_timestamp(time)
      if time.is_a?(Numeric) then format_timestamp(Time.at(time).utc)
      elsif time.is_a?(Time) then time.utc.strftime("%Y%m%d%H%M%S")
      elsif time.is_a?(String) then time
      else raise "can't format as timestamp #{time}" end
    end
    
    def Build.timestamp_to_time(timestamp_as_string)
      Time.utc(
        timestamp_as_string[0..3], # year 
        timestamp_as_string[4..5], # month
        timestamp_as_string[6..7], # day
        timestamp_as_string[8..9], # hour
        timestamp_as_string[10..11], # minute
        timestamp_as_string[12..13] # second
      )
    end
    
    def Build.timestamp_to_i(timestamp_as_string)
      timestamp_to_time(timestamp_as_string).to_i
    end
    
    def build_command_line
      config["build_command_line"]
    end

    def quiet_period
      if config["quiet_period"].nil? then nil else config["quiet_period"].to_i end
    end

    def ==(o)
      return false unless o.is_a? Build
      project_name == o.project_name &&
      status == o.status &&
      config == o.config &&
      timestamp == o.timestamp
    end
    
  end
end

