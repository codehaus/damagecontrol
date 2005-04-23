require 'thread'
require 'yaml'

module DamageControl
  class BuildRequest
    attr_accessor :changeset
    attr_reader :reasons
    
    def initialize(changeset, reason)
      @changeset = changeset
      @reasons = [reason]
    end
  end

  # A queue for builds that is aware of projects' dependencies and schedules builds
  # for changesets in an optimal order.
  class BuildQueue

    # Creates a new BuildQueue that persists itself to +file+.
    def initialize(file=nil)
      @queue = []
      @blocking_queue = Queue.new
      @file = file
    end
    
    # The current queue of requests. Should not be used for popping requests off the queue.
    # Use +pop+ for that.
    def queue
      @queue.dup.freeze
    end
  
    # Schedules a build for a ChangeSet by adding a BuildRequest to the queue. 
    #
    # If the queue already contains a scheduled request for the 
    # same project as +changeset+, then 2 things can happen:
    # * If the already scheduled ChangeSet and new changeset are the same, +reason+ is appended to
    #   the existing request.
    # * If the new changeset is a different (presumably more recent) ChangeSet than the scheduled
    #   one, the new +changeset+ will overwrite the previously scheduled ChangeSet.
    #
    # ChangeSets will be put in the scheduling queue according to their project's
    # dependencies, enqueueing each changeset prior to the ones that depend on it.
    #
    def enqueue(changeset, reason)
      # see if there is already a request for the changeset's project
      req_with_same_project = @queue.find { |req| req.changeset.project == changeset.project }

      if(req_with_same_project)
        # there is already a request for a changeset within the same project.
        # see if the request if for the same changeset, or a different one within same project
        if(req_with_same_project.changeset != changeset)
          # it's a request for a different (presumably later) changeset for the same project.
          # replace the request's changeset and void the reasons (which were for the old one)
          req_with_same_project.changeset = changeset
          req_with_same_project.reasons.clear
        end
        req_with_same_project.reasons << reason
      else
        first_req_with_depending_project = @queue.find { |req| req.changeset.project.depends_on?(changeset.project) }
        index_of_first_cs_with_depending_project = @queue.index(first_req_with_depending_project)
        index_of_first_cs_with_depending_project = index_of_first_cs_with_depending_project ? index_of_first_cs_with_depending_project : -1
        @queue.insert(index_of_first_cs_with_depending_project, BuildRequest.new(changeset, reason))
        # just push a dummy object onto the blocking queue to keep the size the same. This is to ensure blocking pop is working.
        @blocking_queue.push("dummy")
      end
      save
    end
    
    # Retrieves a build request from the queue. If the queue is empty, the calling thread is suspended 
    # until a new changeset is enqueued.
    #
    # TODO: let this method take a BuildStrategy argument that can determine whether an enqueued build 
    # request is eligible for building. The queue would iterate over @queue, and if the BuildStrategy
    # determines that a build is eligible, it will pop off a build as long as it doesn't depend on any other
    # build requests to complete. This approach could be used to implement prioritised builds such as
    # distributed builds. It could also take out requests even if there are pending ones. All the power
    # to the strategy.
    def pop
      discard = @blocking_queue.pop
      result = @queue.pop
      save
      result
    end

    # Returns the queue as a list of hashes. Useful for persisting the queue to disk.
    def as_list
      @queue.collect do |request|
        {:project_name => request.changeset.project.name, :reasons => request.reasons}
      end
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