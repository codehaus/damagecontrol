require 'damagecontrol/scm/AbstractTracker'
require 'damagecontrol/util/FileUtils'

module DamageControl
  class SourceForgeTracker  < AbstractTracker
    include FileUtils
    
    attr_accessor :group_id
    attr_accessor :tracker_id

    def name
      "SourceForge.net"
    end
    
    def url
      "http://sourceforge.net/tracker/?group_id=#{group_id}"
    end

    def highlight(message)
      message.gsub(Regexp.new("#([0-9]+)"),"<a href=\"http://sourceforge.net/tracker/index.php?func=detail&aid=\\1&group_id=" << group_id << "&atid=" << tracker_id << "\">#\\1</a>")
    end
  end
end
