server = 'zebedee'
channel = "#build"
logdir = 'D:\cruise\cruiselogs'

$damagecontrol_home = '../..'
$:<<"#{$damagecontrol_home}/src/ruby"

require 'damagecontrol/CruiseControlLogPoller'
require 'damagecontrol/IRCPublisher'

include DamageControl

hub = Hub.new
CruiseControlLogPoller.new(hub, logdir).start
IRCPublisher.new(hub, server, channel).start

# sleep until ctrl-c
sleep