#!/usr/bin/env ruby

irc_handle = 'rant'
irc_server = '164.38.224.177'
irc_channel = "#build"
logdir = '/cruise/cruiselogs'
website_baseurl = 'http://164.38.244.63:8080/cruisecontrol/buildresults'

$damagecontrol_home = File::expand_path('../..') 
$:<<"#{$damagecontrol_home}/server" 

require 'damagecontrol/simple' 
require 'damagecontrol/Hub'
require 'damagecontrol/SocketTrigger'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/LogWriter'
require 'damagecontrol/SelfUpgrader'
require 'damagecontrol/template/ShortTextTemplate'
require 'damagecontrol/template/HTMLTemplate'
require 'damagecontrol/publisher/IRCPublisher'
require 'damagecontrol/publisher/FilePublisher'
require 'damagecontrol/publisher/GraphPublisher'
require 'damagecontrol/publisher/EmailPublisher'
require 'damagecontrol/publisher/JIRAPublisher'
require 'damagecontrol/cruisecontrol/CruiseControlLogPoller'
require 'damagecontrol/Logging'

include DamageControl

Logging.quiet

start_simple_server(
  :RootDir => ".",
  :SocketTriggerPort => 4711,
  :HttpPort => 4712,
  :HttpsPort => 4713)

irc = IRCPublisher.new(@hub, irc_server, irc_channel, ShortTextTemplate.new)
irc.handle = irc_handle
irc.start
CruiseControlLogPoller.new(@hub, logdir, website_baseurl).start

# wait until ctrl-c
@socket_trigger.join
