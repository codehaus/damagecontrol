require 'damagecontrol/FileSystem'
require 'damagecontrol/scm/DefaultSCMRegistry'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/ant/ant'

module DamageControl

  class Modification
    attr_accessor :developer
    attr_accessor :path
    attr_accessor :message
    attr_accessor :time
  end

  class Build

    attr_accessor :project_name

    # Time for this build in format:
    # <year><month><day><hour><min><sec>
    # Always in timezone UTC
    attr_accessor :timestamp

    attr_accessor :config
    attr_accessor :modification_set
    attr_accessor :label
    attr_accessor :error_message
    attr_accessor :successful
    
    def initialize(project_name = nil, config={})
      @project_name = project_name
      @config = config
      
      @modification_set = []
      @timestamp = Build.format_timestamp(Time.utc(*Time.now.to_a))
    end
    
    def timestamp=(time)
      @timestamp = Build.format_timestamp(time)
    end
    
    def Build.format_timestamp(time)
      if time.is_a?(Integer) then format_timestamp(Time.at(time))
      elsif time.is_a?(Time) then time.strftime("%Y%m%d%H%M%S")
      elsif time.is_a?(String) then time
      else raise "can't format as timestamp #{time}" end
    end
    
    def Build.timestamp_to_i(timestamp_as_string)
      Time.utc(
        timestamp_as_string[0..3], # year 
        timestamp_as_string[4..5], # month
        timestamp_as_string[6..7], # day
        timestamp_as_string[8..9], # hour
        timestamp_as_string[10..11], # minute
        timestamp_as_string[12..13] # second
      ).to_i
    end
    
    def scm_spec
      config["scm_spec"]
    end

    def build_command_line
      config["build_command_line"]
    end
  end
end