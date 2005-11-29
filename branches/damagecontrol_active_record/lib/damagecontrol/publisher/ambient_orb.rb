require 'ambient'

module Ambient
  # Opens up the Ambient::Orb class a little bit
  # so available animations and colors can be used easily in select options
  class Orb
    
    def self.animations
      @@animations.to_a.collect{|kv| [kv[0].to_s, kv[0].to_s]}
    end

    def self.colors
      @@colors.to_a.collect{|kv| [kv[0].to_s, kv[0].to_s]}
    end
  end
end

module DamageControl
  module Publisher
    class AmbientOrb < Base
      attr_accessor :orb_id
      attr_accessor :color
      attr_accessor :animation
      
      def initialize
        @color = {}
        @animation = {}

        init "requested",             "yellow", "slow"
        init "synching_working_copy", "yellow", "fast"
        init "executing",             "yellow", "crescendo"
        init "successful",            "green",  "none"
        init "fixed",                 "green",  "medium"
        init "broken",                "red",    "none"
        init "repeatedly_broken",     "red",    "medium"
      end

      def publish(build, driver=Ambient::Orb.new)
        driver.id = @orb_id 
        driver.color = @color[build.state.name].to_sym
        driver.animation = @animation[build.state.name].to_sym
        driver.update 
      end

    private
    
      def init(state_name, color, animation)
        @color[state_name] = color
        @animation[state_name] = animation
      end

    end
  end
end

