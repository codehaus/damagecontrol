module DamageControl
  module Publisher
    # OS X - See bin/powerpc-darwin
    class SoundPlayer
      def self.play(track)
        `playsound #{File.expand_path(track)}`
      end
    end
  end
end