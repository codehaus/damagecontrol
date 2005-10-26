module DamageControl
  module Publisher
    # iTunes based player for OS X
    class MediaPlayer
      def play(track)
        `playsound #{File.expand_path(track)}`
      end
    end
  end
end