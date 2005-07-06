module DamageControl
  module Publisher
  
    # Base class for publishers. Subclasses must extend this class and call register self.
    class Base
      cattr_accessor :logger

      @@classes = []
      def self.register(cls)
        @@classes << cls unless @@classes.index(cls)
      end

      def self.classes
        @@classes.sort
      end  
    end
  end
end