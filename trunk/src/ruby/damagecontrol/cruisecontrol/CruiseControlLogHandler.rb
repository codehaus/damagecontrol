require 'damagecontrol/Hub'
require 'damagecontrol/FilePoller'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/Build'
require 'damagecontrol/cruisecontrol/CruiseControlLogParser'

module DamageControl

  # File handler to used in conjuction with FilePoller
  class CruiseControlLogHandler
    def initialize(hub)
      @hub = hub
      @ccparser = CruiseControlLogParser.new
    end
  
    def new_file(file)
      build = Build.new
      @ccparser.parse(file, build)
      evt = BuildCompleteEvent.new(build)
      @hub.publish_message(evt)
    end
  end
end