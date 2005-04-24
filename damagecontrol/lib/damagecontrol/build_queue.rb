require 'thread'
require 'yaml'

module DamageControl
  class BuildRequest
    attr_accessor :revision
    attr_reader :reasons
    
    def initialize(revision, reason)
      @revision = revision
      @reasons = [reason]
    end
  end

  # A queue for builds that is aware of projects' dependencies and schedules builds
  # for revisions in an optimal order.
  class BuildQueue

    # Creates a new BuildQueue that persists itself to +file+.
    def initialize(file=nil)
      @pending = []
      @building = []
      @blocking_queue = Queue.new
      @file = file
    end
    
    # The current queue of requests. Should not be used for popping requests off the queue.
    # Use +pop+ for that.
    def queue
      @pending.dup.freeze
    end
  
    # Schedules a build for a Revision by adding a BuildRequest to the queue. 
    #
    # If the queue already contains a scheduled request for the 
    # same project as +revision+, then 2 things can happen:
    # * If the already scheduled Revision and new revision are the same, +reason+ is appended to
    #   the existing request.
    # * If the new revision is a different (presumably more recent) Revision than the scheduled
    #   one, the new +revision+ will overwrite the previously scheduled Revision.
    #
    # Revisions will be put in the scheduling queue according to their project's
    # dependencies, enqueueing each revision prior to the ones that depend on it.
    #
    def enqueue(revision, reason)
      # see if there is already a request for the revision's project
      req_with_same_project = @pending.find { |req| req.revision.project == revision.project }

      if(req_with_same_project)
        # there is already a request for a revision within the same project.
        # see if the request if for the same revision, or a different one within same project
        if(req_with_same_project.revision != revision)
          # it's a request for a different (presumably later) revision for the same project.
          # replace the request's revision and void the reasons (which were for the old one)
          req_with_same_project.revision = revision
          req_with_same_project.reasons.clear
        end
        req_with_same_project.reasons << reason
      else
        first_req_with_depending_project = @pending.find { |req| req.revision.project.depends_on?(revision.project) }
        index_of_first_cs_with_depending_project = @pending.index(first_req_with_depending_project)
        index_of_first_cs_with_depending_project = index_of_first_cs_with_depending_project ? index_of_first_cs_with_depending_project : -1
        @pending.insert(index_of_first_cs_with_depending_project, BuildRequest.new(revision, reason))
        # just push a dummy object onto the blocking queue to keep the size the same. This is to ensure blocking pop is working.
        @blocking_queue.push("dummy")
      end
      save
    end
    
    # Retrieves a build request from the queue. If the queue is empty, the calling thread is suspended 
    # until a new revision is enqueued.
    #
    # TODO: let this method take a Builder argument that can determine whether an enqueued build 
    # request is eligible for building. The queue would iterate over @pending, and if the BuildStrategy
    # determines that a build is eligible, it will pop off a build as long as it doesn't depend on any other
    # build requests to complete. This approach could be used to implement prioritised builds such as
    # distributed builds. It could also take out requests even if there are pending ones. All the power
    # to the strategy.
    def pop(builder)
      discard = @blocking_queue.pop
      req = @pending.delete_at(0)
      @building << req
      save
      req
    end
    
    # Deletes a building request
    def delete(req)
      @building.delete(req)
      save
    end

    # Returns the queue as a list of hashes. Useful for persisting the queue to disk.
    def as_list
      building = @building.collect do |request|
        {:project_name => request.revision.project.name, :reasons => request.reasons, :building => true}
      end
      pending = @pending.collect do |request|
        {:project_name => request.revision.project.name, :reasons => request.reasons, :building => false}
      end
      
      building.concat(pending)
    end
    
  private
  
    # Persist the queue to disk
    def save
      return unless @file
      File.open(@file, 'w') do |out|
        YAML.dump(as_list, out)
      end
    end
    
  end
end