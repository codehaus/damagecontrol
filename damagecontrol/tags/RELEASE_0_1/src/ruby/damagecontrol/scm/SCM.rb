module DamageControl
  class SCMError < RuntimeError
  end

  class SCM
    # determine whether this SCM can handle a particular path
    def handles_spec?(spec)
      false
    end
    
    # checks out (or updates) path to directory
    def checkout(spec, directory)
      raise "can't check out #{spec}"
    end

    # the local directory (CVS module)
    # we might need to change this to something
    # more SCM generic
    def mod(spec)
      raise "don't know how to find mod for #{spec}"
    end
  end
end