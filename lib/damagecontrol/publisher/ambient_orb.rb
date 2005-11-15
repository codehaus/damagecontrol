require 'ambient'

module Ambient
  class Orb
    def self.animations
      @@animations.to_a.collect{|kv| [kv[0], kv[1].to_s]}
    end

    def self.colors
      @@colors.to_a.collect{|kv| [kv[0], kv[1].to_s]}
    end
  end
end

module DamageControl
  module Publisher
    class AmbientOrb < Base
      attr_accessor :orb_id
      
      ::Build::STATES.each do |state|
        attr_accessor state.attr_sym("", "color")
        attr_accessor state.attr_sym("", "animation")
      end

      def initialize
        init "requesting",            "yellow", "slow"
        init "synching_working_copy", "yellow", "fast"
        init "executing",             "yellow", "crescendo"
        init "successful",            "green",  "none"
        init "fixed",                 "green",  "medium"
        init "broken",                "red",    "none"
        init "repeatedly_broken",     "red",    "medium"
      end

      def publish(build, driver=Ambient::Orb.new)
        driver.id = @orb_id 
        driver.color = build_state_attr(build.state, "color").to_sym
        driver.animation = build_state_attr(build.state, "animation").to_sym
        driver.update 
      end

    private
    
      def init(state_name, color, animation)
        instance_variable_set("@#{state_name}_color", color)
        instance_variable_set("@#{state_name}_animation", animation)
      end

    end
  end
end

