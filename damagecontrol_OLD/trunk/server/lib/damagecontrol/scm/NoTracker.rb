module DamageControl
  class NoTracker
    def name
      "No Tracker"
    end
    
    def url
      "#"
    end

    def ==(other_scm)
      return false if self.class != other_scm.class
      true
    end
  end
end
