$VERBOSE = nil

server = 'zebedee'
channel = "#build"
logdir = 'D:\cruise\cruiselogs'

$damagecontrol_home = '../..'
$:<<"#{$damagecontrol_home}/src/ruby"

require 'damagecontrol/cruisecontrol/CruiseControlLogPoller'
require 'damagecontrol/publisher/IRCPublisher'

include DamageControl

hub = Hub.new
CruiseControlLogPoller.new(hub, logdir).start
IRCPublisher.new(hub, server, channel).start

#set_trace_func proc { |event, file, line, id, binding, classname|
#  printf "%8s %s:%-2d %10s %8s\n", event, file, line, id, classname
#}

# sleep until ctrl-c
sleep