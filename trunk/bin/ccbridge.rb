#!/usr/bin/env ruby

#TODO: This stuff doesn't actually work!!!

irc_handle = 'rant'
irc_server = '164.38.224.177'
irc_channel = "#build"
logdir = '/cruise/cruiselogs'
website_baseurl = 'http://164.38.244.63:8080/cruisecontrol/buildresults'

$damagecontrol_home = File::expand_path("#{File.dirname($0)}/../..")
$:.push("#{$damagecontrol_home}/server")

require 'damagecontrol/simple' 
require 'damagecontrol/core/Hub'
require 'damagecontrol/core/SocketTrigger'
require 'damagecontrol/core/BuildExecutor'
require 'damagecontrol/core/LogWriter'
require 'damagecontrol/core/SelfUpgrader'
require 'damagecontrol/template/HTMLTemplate'
require 'damagecontrol/publisher/IRCPublisher'
require 'damagecontrol/publisher/FilePublisher'
require 'damagecontrol/publisher/GraphPublisher'
require 'damagecontrol/publisher/EmailPublisher'
require 'damagecontrol/publisher/JIRAPublisher'
require 'damagecontrol/cruisecontrol/CruiseControlLogPoller'
require 'damagecontrol/util/Logging'

include DamageControl

Logging.quiet

start_simple_server(
  :RootDir => $damagecontrol_home,
  :SocketTriggerPort => 4711,
  :HttpPort => 4712,
  :HttpsPort => 4713)

irc = IRCPublisher.new(@hub, irc_server, irc_channel, "short_text_build_result.erb")
irc.handle = irc_handle
irc.start
CruiseControlLogPoller.new(@hub, logdir, website_baseurl).start

# wait until ctrl-c
@socket_trigger.join
