server = "irc.codehaus.org"
channel = "#damagecontrol"

$damagecontrol_home = File::expand_path('../..')
$:<<"#{$damagecontrol_home}/src/ruby"

require 'damagecontrol/SocketTrigger'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/CruiseControlLogPoller'
require 'damagecontrol/IRCPublisher'
require 'damagecontrol/BuildBootstrapper'

include DamageControl

build = Build.new("picocontainer")
build.basedir = "builds"
build.build_command_line = "maven jar:install"

hub = Hub.new

# all the comps
BuildExecutor.new(hub)
BuildBootstrapper.new(hub, "foo").start
IRCPublisher.new(hub, server, channel).start
SocketTrigger.new(hub).start

# sleep until ctrl-c
sleep
