require 'rscm/annotations'
require 'damagecontrol/project'
require 'rscm/annotations'

# http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/124460
module DamageControl
  module Publisher
    class X10Cm11A < Base
      register self
    
      def name
        "X10-CM11A"
      end    

      def publish(build)
      end
    end
  end
end