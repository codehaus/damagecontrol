require 'rscm/annotations'
require 'damagecontrol/project'

module DamageControl
  module Publisher
  
    # Base class for publishers. Subclasses must extend this class and call register self.
    class Base

      attr_accessor :enabled

      @@classes = []
      def self.register(cls) 
        @@classes << cls unless @@classes.index(cls)
      end      
      def self.classes
        @@classes
      end
  
      Dir[File.dirname(__FILE__) + "/*.rb"].each do |src|
        load(src) unless File.expand_path(src) == File.expand_path(__FILE__)
      end
    end
  end
end