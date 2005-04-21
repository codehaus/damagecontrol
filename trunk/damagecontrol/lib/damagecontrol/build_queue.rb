module DamageControl
  class BuildRequest
    attr_accessor :changeset
    attr_reader :reasons
    
    def initialize(changeset, reason)
      @changeset = changeset
      @reasons = [reason]
    end
  end

  class BuildQueue

    attr_reader :queue
  
    def initialize
      @queue = []
    end
  
    # Schedules a build for a ChangeSet. 
    #
    # If the scheduler already contains a scheduled request for the 
    # same project as +changeset+, then 2 things can happen:
    # * If the scheduled and new changeset are the same, reason is appended to request.
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
      end
    end
    
  end
end