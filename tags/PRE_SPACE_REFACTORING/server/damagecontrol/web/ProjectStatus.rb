module DamageControl
  class ProjectStatus
    attr_reader :name
    
    def initialize(name, build_history_repository)
      @name = name
      @build_history_repository = build_history_repository
    end
    
    def href
      "project?project_name=#{name}"
    end
    
    def image
      "images/lastcompletedstatus?project_name=#{name}"
    end
    
    def last_successful_build
      build_history_repository.last_successful_build(name)
    end
    
    def last_completed_build
      build_history_repository.last_completed_build(name)
    end
    
    def current_build
      current_build = build_history_repository.current_build(name)
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
      if last_successful_build then last_successful_build.time_since_for_humans else "Never built" end
    end
    
    def last_duration
      if last_completed_build then last_completed_build.duration_for_humans else "Never built" end
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
        current_time - current_build.start_time
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
  
    private
    
      attr_reader :build_history_repository
  end
end