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
      attr_accessor :successful_color,        :successful_animation
      attr_accessor :fixed_color,             :fixed_animation
      attr_accessor :broken_color,            :broken_animation
      attr_accessor :repeatedly_broken_color, :repeatedly_broken_animation
      attr_accessor :executing_color,         :executing_animation

      def initialize
        @successful_color            = "green"
        @successful_animation        = "none"
        @fixed_color                 = "green"
        @fixed_animation             = "none"
        @broken_color                = "red"
        @broken_animation            = "none"
        @repeatedly_broken_color     = "red"
        @repeatedly_broken_animation = "medium"
        @executing_color             = "yellow"
        @executing_animation         = "medium"
      end

      def publish(build, driver=Ambient::Orb.new)
        driver.id = @orb_id 
        driver.color = build_status_attr(build, "color").to_sym
        driver.animation = build_status_attr(build, "animation").to_sym
        driver.update 
      end

    end
  end
end

