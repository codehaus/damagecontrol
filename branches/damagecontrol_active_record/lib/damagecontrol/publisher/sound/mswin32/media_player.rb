require 'win32/sound'

module DamageControl
  module Publisher
    # win32/sound (win32utils) based player for Windows
    class MediaPlayer
      def play(track)
        Win32::Sound.play(track)
      end
    end
  end
end