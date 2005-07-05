module DamageControl
  class BuildExecutor

    def initialize
      @build_queue = BuildQueue.new
    end
    
    def build_next
      build = @build_queue.next
      build.execute!
    end
  end
end