require 'damagecontrol/util/FilePoller'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/Build'
require 'damagecontrol/cruisecontrol/CruiseControlLogParser'

module DamageControl

  # File handler to used in conjuction with FilePoller
  class CruiseControlLogPoller < FilePoller
    def initialize(channel, dir_to_poll, website_baseurl)
      super(dir_to_poll)
      @channel = channel
      @ccparser = CruiseControlLogParser.new(website_baseurl)
    end
  
    def new_file(file)
      build = Build.new
      @ccparser.parse(file, build)
      evt = BuildCompleteEvent.new(build)
      @channel.publish_message(evt)
    end
  end
end
