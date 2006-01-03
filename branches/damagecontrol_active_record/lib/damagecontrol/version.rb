module DamageControl
  module VERSION
    unless defined?(MAJOR)
      MAJOR = 0
      MINOR = 6
      TINY  = 0

      ARRAY = [MAJOR, MINOR, TINY]
      STRING = ARRAY.join('.')

      NAME = "DamageControl"
      FULLNAME = "DamageControl Continuous Integration Server"
      URL = "http://damagecontrol.buildpatterns.com/"  
    end
  end
end