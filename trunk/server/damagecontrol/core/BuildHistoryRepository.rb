require 'damagecontrol/core/Build'
require 'damagecontrol/core/AsyncComponent'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/ProjectDirectories'
require 'pebbles/TimeUtils'
require 'yaml'

# Captures and persists build history.
# All reads are from memory, which is populated from files at startup.
# Writes will update memory as well as files.
#
# Instances of this class can also be reached
# through XML-RPC - See xmlrpc/StatusPublisher.rb
# 
# Authors: Steven Meyfroidt, Aslak Hellesoy, Jon Tirsen
module DamageControl

  class BuildHistoryRepository < AsyncComponent

    def initialize(channel, project_directories=nil)
      super(channel)
      @project_directories = project_directories
      @history = {}
      
      if(@project_directories)
        populate_cache_from_files
      end
    end
    
    def current_build(project_name)
      history = history(project_name)
      return nil unless history
      patch_build(history[-1])
    end
    
    def last_completed_build(project_name)
      history = history(project_name)
      return nil unless history
      patch_build(history.reverse.find {|build| build.completed?})
    end
    
    def last_successful_build(project_name)
      history = history(project_name)
      return nil unless history
      patch_build(history.reverse.find {|build| build.status == Build::SUCCESSFUL})
    end

    def process_message(message)
      if message.is_a?(BuildEvent) && !message.is_a?(BuildProgressEvent)
        register(message.build)
      end
    end
    
    def history(project_name)
      return [] unless @history.has_key?(project_name)
      result = @history[project_name]
      result
    end
    
    def register(build)
      history = history(build.project_name)
      if(history.empty?)
        @history[build.project_name] = history
      end

      history << build unless history.index(build)
      if(@project_directories)
        dump(history, build.project_name)
      end
    end
    
    def project_names
      @history.keys.sort
    end
    
    # Returns a map of time -> [build]
    # The time represents a time period of a day, week or month
    # date_field should be :day, :week or :month
    def group_by_period(project_name, interval)
      build_periods = {}
      build_list = history(project_name)
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

  private

    def populate_cache_from_files
      @project_directories.project_names.each do |project_name|
        builds = load(project_name)
        @history[project_name] = builds unless builds.nil?
      end
    end

    def load(project_name)
      builds = nil
      filename = history_file(project_name)
      if(File.exist?(filename))
        file = File.new(filename)
        yaml = file.read
        builds = YAML::load(yaml)
        file.close

        if(!builds.is_a?(Array))
          raise "#{filename} should contain the YAML representation of a Ruby Array of Build!"
        end
      end
      builds
    end
    
    # HACK OF DEATH:
    # some xmlrpc implementations get very confused by an empty struct
    # so we'll patch it by adding a pointless property in it
    # (did that take me like on day to figure out?!)
    # -- Jon Tirsen
    def patch_build(build)
      build.config["apa"]="banan" unless build.nil?
      build
    end
    
    def dump(history, project_name)
      out = File.new(history_file(project_name), "w")
      YAML::dump(history, out)
      out.close
    end

    def history_file(project_name)
      File.expand_path(@project_directories.build_history_file(project_name))
    end
    
  end
end
