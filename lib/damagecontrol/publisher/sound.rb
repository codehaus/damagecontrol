# Load platform-specific sound player
require File.expand_path(File.dirname(__FILE__) + "/sound/" + DamageControl::Platform.family + "/sound_player")

module DamageControl
  module Publisher
    class Sound < Base

      attr_accessor :executing_sound, :successful_sound, :fixed_sound, :broken_sound, :repeatedly_broken_sound

      # Finds all sound files matching +glob+.
      def self.files
        Dir["#{DC_DATA_DIR}/sound/*"].collect{|f| File.basename(f)}
      end

      def initialize
        @executing_sound         = "hal_moment.wav"
        @successful_sound        = "hal_well.wav"
        @fixed_sound             = "hal_better.wav"
        @broken_sound            = "hal_fault.wav"
        @repeatedly_broken_sound = "hal_error.wav"
      end

      def publish(build)
        sound = build_status_attr(build, "sound")
        sound_path = "#{DC_DATA_DIR}/sound/#{sound}"
        SoundPlayer.play(sound_path)
      end
      
    end
  end
end
