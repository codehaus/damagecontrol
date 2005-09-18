module DamageControl
  module Publisher
    class Sound < Base
      include Platform

      register self
      
      attr_accessor :executing_sound, :successful_sound, :fixed_sound, :broken_sound, :repeatedly_broken_sound

      def initialize
        @executing_sound = File.expand_path(File.dirname(__FILE__) + "/sound/better.wav")
        @successful_sound = File.expand_path(File.dirname(__FILE__) + "/sound/well.wav")
        @fixed_sound = File.expand_path(File.dirname(__FILE__) + "/sound/better.wav")
        @broken_sound = File.expand_path(File.dirname(__FILE__) + "/sound/fault.wav")
        @repeatedly_broken_sound = File.expand_path(File.dirname(__FILE__) + "/sound/error.wav")
      end

      def publish(build)
        track = sound_track(build)
        # Load platform-specific mediaplayer
        require File.expand_path(File.dirname(__FILE__) + "/sound/" + family + "/media_player")
        MediaPlayer.new.play(track)
      end
      
    private
    
      def sound_track(build)
        # TODO: something cleaner. Why doesn't the class comparison work??
        case build.state.class.name
          when Build::Executing.name
            return executing_sound
          when Build::Successful.name
            return successful_sound
          when Build::Fixed.name
            return fixed_sound
          when Build::Broken.name
            return broken_sound
          when Build::RepeatedlyBroken.name
            return repeatedly_broken_sound
        end
      end
      
    end
  end
end
