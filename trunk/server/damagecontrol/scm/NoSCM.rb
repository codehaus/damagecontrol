require 'ftools'

module DamageControl
  require 'damagecontrol/scm/AbstractSCM'
  
  class NoSCM < AbstractSCM
    def method_missing(*args)
      "does nothing :-)"
    end
    
    def checkout(time = nil, &proc)
      File.mkpath(checkout_dir)
    end
  end
end