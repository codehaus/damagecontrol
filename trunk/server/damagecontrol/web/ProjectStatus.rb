require 'pebbles/TimeUtils'

module DamageControl
  class ProjectStatus
    include Pebbles::TimeUtils

    attr_reader :project_name

    def initialize(project_name, build_history_repository)
      @project_name = project_name
      @build_history_repository = build_history_repository
    end
    
    def href
      "project/#{@project_name}"
    end
    
    def image
      "images/lastcompletedstatus/#{@project_name}"
      color = "grey"
      pulse = ""
      build = last_completed_build
      
      if(build && build.completed?)
        color = if build.successful? then "green" else "red" end
        pulse = "-pulse" if ongoing_build?
      end
      image = "images/#{color}#{pulse}-32.gif"
    end
    
    def last_successful_build
      @build_history_repository.last_successful_build(@project_name)
    end
    
    def last_completed_build
      @build_history_repository.last_completed_build(@project_name)
    end
    
    def current_build
      current_build = @build_history_repository.current_build(@project_name)
      current_build = nil if current_build != nil && current_build.completed?
      current_build
    end
    
    def label
      if last_successful_build
        " (##{last_successful_build.label})"
      else
        ""
      end
    end
    
    def time_since_last_success
			if(last_successful_build  && last_successful_build.dc_end_time)
			"#{Time.now.utc.difference_as_text(last_successful_build.dc_end_time)} ago"
 	    else 
 	    	"Never successfuly built" 
 	    end
    end
    
    def last_duration
      if(last_completed_build && last_completed_build.duration)
        duration_as_text(last_completed_build.duration)
      else 
        "Never built" 
      end
    end
    
    def current_duration
      if current_build then current_build.duration_for_humans else "No ongoing build" end
    end
    
    def ongoing_build?
      current_build != nil
    end
    
    def percentage_done
      return 0 unless current_build && benchmark_build
      return 95 if longer_than_last_build?
      (current_build_duration / benchmark_build.duration * 100).to_i
    end
    
    def percentage_left
      return 0 unless current_build && benchmark_build
      100 - percentage_done
    end
    
  protected

    def current_build_duration
      current_time - current_build.dc_start_time
    end

    def longer_than_last_build?
      current_build_duration > benchmark_build.duration
    end

    def benchmark_build
      last_successful_build || last_completed_build
    end

    # can be overloaded during testing
    def current_time
      Time.now.utc
    end
  end
end