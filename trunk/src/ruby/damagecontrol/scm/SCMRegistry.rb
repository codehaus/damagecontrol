require 'damagecontrol/scm/SCM'

module DamageControl

  # Facade to all supported SCMs
  class SCMRegistry < SCM    
    def initialize
      @scms = []
    end

    def add_scm(scm)
      @scms<<scm
    end

    def find_scm(spec)
      @scms.find {|scm| scm.handles_spec?(spec) }
    end

    def handles_spec?(path)
      find_scm(path)
    end
        
    # checks out (or updates) path to directory
    def checkout(path, directory, &proc)
      scm = find_scm(path)
      if scm
        scm.checkout(path, directory, &proc)
      else
        super(path, directory, &proc)
      end
    end

    def changes(spec, directory, time_before, time_after)
      scm = find_scm(spec)
      if scm
        scm.changes(spec, directory, time_before, time_after)
      else
        super(path, directory, &proc)
      end
    end

    # TODO: obsolete?
    def get_changes(spec, from, to)
      scm = find_scm(spec)
      if scm
        scm.get_changes(spec, from, to)
      else
        super(spec)
      end
    end

    def mod(spec)
      scm = find_scm(spec)
      if scm
        scm.mod(spec)
      else
        super(spec)
      end
    end

    def branch(spec)
      scm = find_scm(spec)
      if scm
        scm.branch(spec)
      else
        super(spec)
      end
    end

    def host(spec)
      scm = find_scm(spec)
      if scm
        scm.host(spec)
      else
        super(spec)
      end
    end

  end
end