require 'damagecontrol/scm/AbstractTracker'
require 'damagecontrol/util/FileUtils'

module DamageControl
  class RubyForgeTracker  < AbstractTracker
    include FileUtils
    
    attr_accessor :group_id
    attr_accessor :tracker_id

    def name
      "RubyForge.org"
    end
    
    def url
      "http://rubyforge.org/tracker/?group_id=#{group_id}"
    end

    def highlight(message)
      message.gsub(/#([0-9]+)/,"<a href=\"http://rubyforge.org/tracker/index.php?func=detail&aid=\\1&group_id=#{group_id}&atid=#{tracker_id}\">#\\1</a>")
    end
  end
end
