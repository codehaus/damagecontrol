require 'ftools'

module DamageControl
  require 'damagecontrol/scm/AbstractSCM'
  
  class NoSCM < AbstractSCM
    def name
      "NoSCM"
    end

    def method_missing(*args)
      "NoSCM does nothing :-)"
      self
    end
    
    def checkout(checkout_dir, time = nil, &proc)
      File.mkpath(checkout_dir)
      nil
    end
  end
end