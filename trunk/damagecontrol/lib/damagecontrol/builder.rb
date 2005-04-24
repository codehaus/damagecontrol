module DamageControl
  # A builder builds a revision
  class Builder
  
    def initialize(build_queue)
      @build_queue = build_queue
    end
    
    # Builds next build request in queue
    def build_next
      request = @build_queue.pop(self)
      request.revision.build!(request.reasons)
      @build_queue.delete(request)
    end
  end
end