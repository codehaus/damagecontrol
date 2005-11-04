require 'win32/sound'

module DamageControl
  module Publisher
    # win32/sound (win32utils) based player for Windows
    class SoundPlayer
      def play(track)
        Win32::Sound.play(track)
      end
    end
  end
end