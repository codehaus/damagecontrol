require 'damagecontrol/Build'
require 'damagecontrol/AsyncComponent'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/pebbles/TimeUtils'

# Captures and persists build history
# Instances of this class can also be reached
# through XML-RPC - See XMLRPCStatusPublisher.rb
# 
# Authors: Steven Meyfroidt, Aslak Hellesoy
module DamageControl

  class BuildHistoryRepository < AsyncComponent
  
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
        @filename = expanded
      end
    end
    
    def last_succesful_build(project_name)
      build_history(project_name).reverse.find {|build| build.status == Build::SUCCESSFUL}
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
      build_array.sort! {|b1, b2| b1.timestamp_as_time <=> b2.timestamp_as_time }
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
        if(build_history(project_name) != [])
          result_map = {project_name => build_history(project_name)}
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
    
    def build_history(project_name)
      return [] unless @builds.has_key?(project_name)
      @builds[project_name]
    end

    def get_project_names()
      @builds.keys
    end

    # Returns a map of time -> [build]
    # The time represents a time period of a day, week or month
    # date_field should be :day, :week or :month
    def group_by_period(project_name, interval)
      build_periods = {}
      build_list = get_build_list_map(project_name)[project_name]
      build_list.each do |build|
        timestamp = build.timestamp_as_time
        period_number, period_start_date = timestamp.get_period_info(interval)
        builds_during_that_period = build_periods[period_start_date]
        if(builds_during_that_period.nil?)
          builds_during_that_period = []
          build_periods[period_start_date] = builds_during_that_period
        end

        builds_during_that_period << build
      end
      build_periods
    end

  end
end
