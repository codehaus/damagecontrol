module DamageControl
  # A builder builds a changeset
  class Builder
  
    def initialize(build_queue)
      @build_queue = build_queue
    end
    
    # Builds next build request in queue
    def build_next
      Log.info "Popping build request from queue..."
      request = @build_queue.pop(self)
      Log.info "Building #{request.changeset.project.name}"
      request.changeset.build!(request.reasons)
      @build_queue.delete(request)
    end
  end
end