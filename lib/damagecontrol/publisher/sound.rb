module DamageControl
  module Publisher
    class Sound < Base
      include Platform

      attr_accessor :executing_sound, :successful_sound, :fixed_sound, :broken_sound, :repeatedly_broken_sound

      def initialize
        @executing_sound = File.expand_path(File.dirname(__FILE__) + "/sound/better.wav")
        @successful_sound = File.expand_path(File.dirname(__FILE__) + "/sound/well.wav")
        @fixed_sound = File.expand_path(File.dirname(__FILE__) + "/sound/better.wav")
        @broken_sound = File.expand_path(File.dirname(__FILE__) + "/sound/fault.wav")
        @repeatedly_broken_sound = File.expand_path(File.dirname(__FILE__) + "/sound/error.wav")
      end

      def publish(build)
        sound = build_status_attr(build, "sound")
        # Load platform-specific mediaplayer
        require File.expand_path(File.dirname(__FILE__) + "/sound/" + family + "/media_player")
        MediaPlayer.new.play(sound)
      end
      
    end
  end
end
