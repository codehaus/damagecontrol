#!/usr/bin/env ruby

$damagecontrol_home = File::expand_path('../..') 
$:<<"#{$damagecontrol_home}/src/ruby" 
 
require 'damagecontrol/Hub' 
require 'damagecontrol/BuildExecutor' 
require 'damagecontrol/LogWriter'
require 'damagecontrol/template/HTMLTemplate'
require 'damagecontrol/template/ShortTextTemplate'
require 'damagecontrol/publisher/FilePublisher'
require 'damagecontrol/publisher/JabberPublisher' 

include DamageControl 

def seconds(i)
	i * 1000
end

buildRoot = File.expand_path(".") 
 
hub = Hub.new 
BuildExecutor.new(hub, "#{buildRoot}/checkout").start

# Configure build
config = {}
config["build_command_line"] = "echo Hello World using Jabber!"
LogWriter.new(hub, "#{buildRoot}/log")

# Register the publishers.
FilePublisher.new(hub, "#{buildRoot}/report", HTMLTemplate.new).start 
JabberPublisher.new(hub, "damagecontrol.test@jabber.com/Work", "damagecontrol", ["damagecontrol.testrecipient@jabber.com/Work"], ShortTextTemplate.new).start

# Start new build every x-seconds
timer = Timer.new {
	build = Build.new("hello-world", config)
	hub.publish_message(BuildRequestEvent.new(build))
}
timer.interval = seconds(30)
timer.start

#sleep till Ctrl-C
sleep

