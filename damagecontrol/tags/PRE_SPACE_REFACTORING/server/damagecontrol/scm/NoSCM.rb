module DamageControl
  require 'damagecontrol/scm/AbstractSCM'
  
  class NoSCM < AbstractSCM
    def method_missing(*args)
      "does nothing :-)"
    end
  end
end