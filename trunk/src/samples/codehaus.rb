#!/usr/bin/env ruby

$damagecontrol_home = File::expand_path('../..') 
$:<<"#{$damagecontrol_home}/src/ruby" 
 
require 'damagecontrol/Hub' 
require 'damagecontrol/SocketTrigger' 
require 'damagecontrol/BuildExecutor' 
require 'damagecontrol/LogWriter' 
require 'damagecontrol/SelfUpgrader' 
require 'damagecontrol/template/ShortTextTemplate' 
require 'damagecontrol/template/HTMLTemplate' 
require 'damagecontrol/publisher/IRCPublisher' 
require 'damagecontrol/publisher/FilePublisher' 
require 'damagecontrol/publisher/EmailPublisher' 
require 'damagecontrol/publisher/JIRAPublisher' 

include DamageControl

buildRoot = File.expand_path("~/build") 
 
start_simple_server("#{buildRoot}/checkout", 4711, ["127.0.0.1", "66.216.68.111", "81.5.134.59" ])

LogWriter.new(@hub, "#{buildRoot}/log")
FilePublisher.new(@hub, "#{buildRoot}/report", HTMLTemplate.new).start 
IRCPublisher.new(@hub, "irc.codehaus.org", "\#damagecontrol", ShortTextTemplate.new).start
EmailPublisher.new(@hub, ShortTextTemplate.new, HTMLTemplate.new, "dcontrol@builds.codehaus.org").start
JIRAPublisher.new(@hub, ShortTextTemplate.new, "jira.codehaus.org").start
SelfUpgrader.new(@hub).start

# wait until ctrl-c 
@socket_trigger.join 
