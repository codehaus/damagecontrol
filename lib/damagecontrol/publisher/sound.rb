module DamageControl
  module Publisher
    class Sound < Base
      include Platform

      attr_accessor :executing_sound, :successful_sound, :fixed_sound, :broken_sound, :repeatedly_broken_sound

      def initialize
        @executing_sound = "hal_moment.wav"
        @successful_sound = "hal_well.wav"
        @fixed_sound = "better.wav"
        @broken_sound = "hal_fault.wav"
        @repeatedly_broken_sound = "error.wav"
      end

      def publish(build)
        sound = build_status_attr(build, "sound")
        # Load platform-specific mediaplayer
        require File.expand_path(File.dirname(__FILE__) + "/sound/" + family + "/media_player")
        sound_path = "#{RAILS_ROOT}/sound/#{sound}"
        MediaPlayer.new.play(sound_path)
      end
      
    end
  end
end
