require 'damagecontrol/Build'
require 'damagecontrol/AsyncComponent'
require 'damagecontrol/BuildEvents'

# Captures and persists build history
# Instances of this class can also be reached
# through XML-RPC - See XMLRPCStatusPublisher.rb
# 
# Authors: Steven Meyfroidt, Aslak Hellesoy
module DamageControl

  class BuildHistoryPublisher < AsyncComponent
  
    def initialize(channel, filename=nil)
      super(channel)
      @builds = Hash.new
      if(filename != nil)
        expanded = File.expand_path(filename)
        if(File.exist?(expanded))
          file = File.new(expanded)
          @builds = YAML::load(file.read)
          file.close
        end
        @filename = filename
      end
    end

    def process_message(message)
      if message.is_a?(BuildEvent) && !message.is_a?(BuildProgressEvent)
        register(message.build)
      end
    end

    def register(build)
      build_array = @builds[build.project_name]
      if(build_array == nil)
        build_array = []
        @builds[build.project_name]=build_array
      end
      build_array << build unless build_array.index(build)
      if(@filename != nil)
        out = File.new(@filename, "w")
        YAML::dump(@builds, out)
        out.close
      end
    end
    
    # Returns a map of array of build, project name as key. if project_name 
    # is nil then all the builds, otherwise only for the specified name
    # If number_of_builds is specified, each list will contain maximum
    # that number of builds - from the end of the original list
    def get_build_list_map(project_name=nil, number_of_builds=nil)
      result_map = nil
      if(project_name != nil)
        if(@builds[project_name] != nil)
          result_map = {project_name => @builds[project_name]}
        else
          return Hash.new
        end
      else
        result_map = @builds
      end

      if(number_of_builds != nil)
        #filter out the end of each list
        result = Hash.new
        @builds.each_pair{ |project_name, build_list|
          length = number_of_builds > build_list.length ? build_list.length : number_of_builds
          result[project_name] = build_list[-length, length]
        }
        return result
      else
        return result_map
      end
    end

    def get_project_names()
      @builds.keys
    end

  end
end
