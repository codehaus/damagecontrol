module DamageControl
  module Publisher
    class Sound < Base
      include Platform

      attr_accessor :executing_sound, :successful_sound, :fixed_sound, :broken_sound, :repeatedly_broken_sound

      def initialize
        @executing_sound         = "hal_moment.wav"
        @successful_sound        = "hal_well.wav"
        @fixed_sound             = "hal_better.wav"
        @broken_sound            = "hal_fault.wav"
        @repeatedly_broken_sound = "hal_error.wav"
      end

      def publish(build)
        sound = build_status_attr(build, "sound")
        # Load platform-specific sound player
        require File.expand_path(File.dirname(__FILE__) + "/sound/" + family + "/sound_player")
        sound_path = "#{RAILS_ROOT}/sound/#{sound}"
        SoundPlayer.new.play(sound_path)
      end
      
    end
  end
end
