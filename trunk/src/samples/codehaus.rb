$damagecontrol_home = File::expand_path('../..')
$:<<"#{$damagecontrol_home}/src/ruby"

require 'damagecontrol/Hub'
require 'damagecontrol/SocketTrigger'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/LogWriter'
require 'damagecontrol/template/ShortTextTemplate'
require 'damagecontrol/template/HTMLTemplate'
require 'damagecontrol/publisher/IRCPublisher'
require 'damagecontrol/publisher/FilePublisher'

include DamageControl

hub = Hub.new

BuildExecutor.new(hub, "dc_builds")
LogWriter.new(hub, "dc_logs")
FilePublisher.new(hub, "dc_reports", HTMLTemplate.new).start
IRCPublisher.new(hub, "irc.codehaus.org", "\#damagecontrol", ShortTextTemplate.new).start
st = SocketTrigger.new(hub, "C:\\dc", 4713).start

# wait until ctrl-c
st.join
