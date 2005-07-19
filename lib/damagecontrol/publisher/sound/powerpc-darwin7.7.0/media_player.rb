module DamageControl
  module Publisher
    # iTunes based player for OS X
    class MediaPlayer
      def play(track)
        # Fork to avoid mangling env for other processes
        pid = fork do
          # Old OS X (pre 10.4) applescript doesn't support args on cmd line(!)
          ENV["track_name"] = track
          apple_script = File.dirname(__FILE__) + "/add_track.scpt"
          IO.popen("osascript #{apple_script}")
        end
        Process.waitpid2(pid)
      end
    end
  end
end