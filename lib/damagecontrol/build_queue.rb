module DamageControl
  # This class is responsible for managing the queue of requested builds
  class BuildQueue
  
    # Creates a new BuildQueue. +build_finder+ can be passed in
    # to improve testability.
    def initialize(build_finder=::Build)
      @build_finder = build_finder
    end
  
    # Returns the next build to be executed.
    def next
      requested = load_requested_blocking
      requested[0]
    end

  private

    def load_requested_blocking
      result = nil
      while(true)
        result = load_requested
        if(result.empty?)
          sleep(2)
        else
          break
        end
      end
      result
    end

    def load_requested
      @build_finder.find_all_by_status(::Build::REQUESTED)
    end
  end
end