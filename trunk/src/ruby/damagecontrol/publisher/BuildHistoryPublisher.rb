require 'damagecontrol/Build'

# Captures and persists build history
# Instances of this class can also be reached
# through XML-RPC - See XMLRPCStatusPublisher.rb
# 
# Authors: Steven Meyfroidt, Aslak Hellesoy
module DamageControl

  class BuildHistoryPublisher
    def initialize(file=nil)
      if(file != nil)
        @file = file
        @builds = Hash.new
      else
        @builds = Hash.new
      end
    end

    def register(build)
      build_array = @builds[build.project_name]
      if(build_array == nil)
        build_array = []
        @builds[build.project_name]=build_array
      end
      build_array << build unless build_array.index(build)
      YAML::dump(@builds, @file) unless @file == nil      
    end
    
    # returns a map of array of build, project name as key. if project_name 
    # is nil then all the builds, otherwise only for the specified name
    def get_build_list_map(project_name=nil)
      if(project_name != nil)
        {project_name => @builds[project_name]}
      else
        @builds
      end
    end

    def get_project_names()
      @builds.keys
    end

  end
end
