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
    attr_accessor :config
    attr_accessor :timestamp
    attr_accessor :modification_set
    attr_accessor :label
    attr_accessor :error_message
    attr_accessor :successful
    
    def initialize(project_name = nil, config={})
      @project_name = project_name
      @config = config
      
      @modification_set = []
      @timestamp = Build.format_timestamp(Time.now)
    end
    
    def Build.format_timestamp(time)
      time.strftime("%Y%m%d%H%M%S")
    end
    
    def scm_spec
      config["scm_spec"]
    end

    def build_command_line
      config["build_command_line"]
    end
  end
end