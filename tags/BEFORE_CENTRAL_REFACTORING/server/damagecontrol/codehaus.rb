#!/usr/bin/env ruby

$damagecontrol_home = File::expand_path('../..') 
$:<<"#{$damagecontrol_home}/server" 

require 'damagecontrol/simple' 
require 'damagecontrol/core/Hub' 
require 'damagecontrol/core/SocketTrigger' 
require 'damagecontrol/core/BuildExecutor' 
require 'damagecontrol/core/LogWriter' 
require 'damagecontrol/core/SelfUpgrader' 
require 'damagecontrol/template/ShortTextTemplate' 
require 'damagecontrol/template/HTMLTemplate' 
require 'damagecontrol/publisher/IRCPublisher' 
require 'damagecontrol/publisher/FilePublisher' 
require 'damagecontrol/publisher/GraphPublisher' 
require 'damagecontrol/publisher/EmailPublisher' 
require 'damagecontrol/publisher/JIRAPublisher'
require 'damagecontrol/util/Logging'

include DamageControl

Logging.quiet

buildRoot = File.expand_path("~/build")
#buildRoot = File.expand_path(".") 

 
start_simple_server(
  :RootDir => "#{buildRoot}", 
  :SocketTriggerPort => 4711, 
  :HttpPort => 4712,
  :HttpsPort => 4713,
  :AllowIPs => ["127.0.0.1", "64.7.141.17", "66.216.68.111", "81.5.134.59", "217.158.24.17" ])

FilePublisher.new(@hub, "#{buildRoot}/report", HTMLTemplate.new).start 
GraphPublisher.new(@hub, "#{buildRoot}/report", @build_history_repository).start 
IRCPublisher.new(@hub, "irc.codehaus.org", "\#damagecontrol", ShortTextTemplate.new).start
EmailPublisher.new(@hub, ShortTextTemplate.new, HTMLTemplate.new, "dcontrol@builds.codehaus.org").start
#JIRAPublisher.new(@hub, ShortTextTemplate.new, "jira.codehaus.org").start
SelfUpgrader.new(@hub).start

# wait until ctrl-c 
@socket_trigger.join 