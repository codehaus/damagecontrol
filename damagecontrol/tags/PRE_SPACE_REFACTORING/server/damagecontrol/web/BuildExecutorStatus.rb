module DamageControl
  class BuildExecutorStatus
    attr_reader :build_executor
    attr_reader :index
    
    def initialize(index, build_executor, build_history_repository)
      @index = index
      @build_executor = build_executor
      @build_history_repository = build_history_repository
    end
    
    def status_message
      build_executor.status_message
    end
    
    def last_successful_build
      build_history_repository.last_successful_build(current_build.project_name)
    end
    
    def last_completed_build
      build_history_repository.last_completed_build(current_build.project_name)
    end
    
    def current_build
      build_executor.scheduled_build
    end
    
    def build_process_executing?
      build_executor.build_process_executing?
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