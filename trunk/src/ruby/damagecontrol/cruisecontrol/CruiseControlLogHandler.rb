require 'damagecontrol/Hub'
require 'damagecontrol/FilePoller'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/BuildResult'
require 'damagecontrol/cruisecontrol/CruiseControlLogParser'

module DamageControl

  # File handler to used in conjuction with FilePoller
  class CruiseControlLogHandler
    def initialize(hub)
      @hub = hub
      @ccparser = CruiseControlLogParser.new
    end
  
    def new_file(file)
      build_result = BuildResult.new
      @ccparser.parse(file, build_result)
      evt = BuildCompleteEvent.new(build_result)
      @hub.publish_message(evt)
    end
  end
end