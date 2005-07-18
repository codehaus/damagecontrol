module DamageControl
  # Base class for plugins. Each plugin family should subclass this class, and each
  # plugin in that family should extend that class.
  class Plugin
    cattr_accessor :logger

    def self.become_parent
      unless defined? @@classes
        class_eval <<-EOS
          @@classes = []
          def self.register(cls)
            @@classes << cls unless @@classes.index(cls)
          end

          def self.classes
            @@classes.sort
          end
        EOS
      end
    end
    
    def name
      self.class.name.demodulize
    end
    
    def htmlize(str)
      str.gsub(/\n/, "<br/>")
    end

  end
end