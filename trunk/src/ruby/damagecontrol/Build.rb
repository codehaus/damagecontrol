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
    attr_accessor :scm_spec
    attr_accessor :build_command_line
    attr_accessor :timestamp
    attr_accessor :modification_set
    attr_accessor :label
    attr_accessor :error_message
    attr_accessor :successful
    
    def initialize(project_name = nil, scm_spec = nil, build_command_line = nil)
      @project_name = project_name
      @scm_spec = scm_spec
      @build_command_line = build_command_line
      
      @modification_set = []
      @timestamp = Build.format_timestamp(Time.now)
    end
    
    def Build.format_timestamp(time)
      time.strftime("%Y%m%d%H%M%S")
    end
    
  end
end