module DamageControl
  class SCM
    # determine whether this SCM can handle a particular path
    def handles_spec?(spec)
      false
    end
    
    # checks out (or updates) path to directory
    def checkout(spec, directory)
      raise "can't check out #{spec}"
    end
  end
end