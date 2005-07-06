require 'active_record'
module DamageControl
  # This class is responsible for managing the queue of requested builds.
  # It currently doesn't apply any particular algorithm to decide what gets
  # built in what order (in the case when there are several requested builds).
  class BuildQueue
  
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
          sleep(10)
        else
          break
        end
      end
      result
    end

    def load_requested
      # All builds without state (yet) are considered requested
      Build.find_all_by_state(nil)
    end
  end
end