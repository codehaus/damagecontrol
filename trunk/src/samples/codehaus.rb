server = "irc.codehaus.org"
channel = "#build"

$damagecontrol_home = File::expand_path('../..')
$:<<"#{$damagecontrol_home}/src/ruby"

require 'damagecontrol/SocketTrigger'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/CruiseControlLogPoller'
require 'damagecontrol/IRCPublisher'

include DamageControl

project = Project.new("picocontainer")
project.basedir = "~/pico"
project.build_command_line = "maven jar:install"
hub = Hub.new
BuildExecutor.new(hub)
IRCPublisher.new(hub, server, channel).start
SocketTrigger.new(hub,project).start

# sleep until ctrl-c
sleep
