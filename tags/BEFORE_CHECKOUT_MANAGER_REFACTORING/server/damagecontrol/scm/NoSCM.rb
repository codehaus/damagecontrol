require 'ftools'

module DamageControl
  require 'damagecontrol/scm/AbstractSCM'
  
  class NoSCM < AbstractSCM
    def method_missing(*args)
      "NoSCM does nothing :-)"
    end
    
    def checkout(checkout_dir, time = nil, &proc)
      File.mkpath(checkout_dir)
    end
  end
end