require 'damagecontrol/Hub'
require 'damagecontrol/FilePoller'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/Build'
require 'damagecontrol/cruisecontrol/CruiseControlLogParser'

module DamageControl

  # File handler to used in conjuction with FilePoller
  class CruiseControlLogPoller < FilePoller
    def initialize(hub, dir_to_poll)
      super(dir_to_poll)
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