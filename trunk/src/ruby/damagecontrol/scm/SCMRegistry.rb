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

    def find_scm(path)
      @scms.find {|scm| scm.handles_path?(path) }
    end

    def handles_path?(path)
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

  end
end