module DamageControl
  module Publisher
    # player for OS X
    class MediaPlayer
      def play(track)
        `playsound #{File.expand_path(track)}`
      end
    end
  end
end