require 'damagecontrol/Hub'
require 'damagecontrol/Project'
require 'damagecontrol/Timer'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/BuildRequestEvent'
require 'damagecontrol/WebsitePublisher'
require 'damagecontrol/LogWriter'

include DamageControl

def seconds(i)
	i * 1000
end

#configure build
project = Project.new("hello-world")
project.build_command_line = "echo Hello world!"

#register components
hub = Hub.new
LogWriter.new(hub)
BuildExecutor.new(hub)
WebsitePublisher.new(hub)

#start new build every second
timer = Timer.new {
	hub.publish_message(BuildRequestEvent.new(project))
	timer.start
}
timer.interval = seconds(1)
timer.start

#sleep till Ctrl-C
sleep
