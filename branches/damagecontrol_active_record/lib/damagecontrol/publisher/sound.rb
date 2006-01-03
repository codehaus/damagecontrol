# Load platform-specific sound player
@@sound_player = File.expand_path(File.dirname(__FILE__) + "/sound/" + DamageControl::RSCM::Platform.family + "/sound_player.rb")
def self.supported?
  File.exist? @@sound_player
end
require @@sound_player if supported?

module DamageControl
  module Publisher
    class Sound < Base
      attr_accessor :sound

      # Finds all sound files.
      def self.sounds
        Dir["#{RAILS_ROOT}/sound/*"].collect{|f| File.basename(f)}
      end

      def initialize
        @sound = {
          'requested'             => "hal_nothing.wav",
          'synching_working_copy' => "hal_moment.wav",
          'executing'             => "hal_decision.wav",
          'successful'            => "hal_well.wav",
          'fixed'                 => "hal_better.wav",
          'broken'                => "hal_fault.wav",
          'repeatedly_broken'     => "hal_error.wav"
        }
      end

      def publish(build)
        sound = @sound[build.state.name]
        # TODO: use DC_DATA_DIR (we must copy sounds out)
        sound_path = File.expand_path("#{RAILS_ROOT}/sound/#{sound}")
        raise "File not found: #{sound_path}" unless File.exist?(sound_path)
        SoundPlayer.play(sound_path)
        "#{sound} was played on the DamageControl server."
      end
      
    end
  end
end
