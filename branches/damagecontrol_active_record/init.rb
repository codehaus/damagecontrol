require 'rubygems'
require 'cmdparse'
require File.dirname(__FILE__) + '/lib/damagecontrol/version'
require File.dirname(__FILE__) + '/lib/damagecontrol/process/scm_poller'
require File.dirname(__FILE__) + '/lib/damagecontrol/process/builder'
require File.dirname(__FILE__) + '/lib/damagecontrol/process/server'

cmd = CmdParse::CommandParser.new(true)
cmd.program_name = DamageControl::VERSION::NAME
cmd.program_version = DamageControl::VERSION::ARRAY

scm_poller = DamageControl::Process::ScmPoller.new
builder    = DamageControl::Process::Builder.new
server     = DamageControl::Process::Server.new

cmd.add_command(CmdParse::HelpCommand.new)
cmd.add_command(CmdParse::VersionCommand.new)
rake = CmdParse::Command.new("rake", false)
rake.set_execution_block do |args|
  rscm_dir = File.expand_path(File.dirname(__FILE__) + '/vendor/plugins/rscm-0.4.0')
  rake_dir = File.expand_path(File.dirname(__FILE__) + '/vendor/plugins/rake-0.6.2')
  cmd = "ruby -I#{rake_dir}/lib:#{rscm_dir}/lib #{rake_dir}/bin/rake #{args.join(' ')}"
  puts cmd
  `#{cmd}`
end
cmd.add_command(rake)
cmd.add_command(DamageControl::Process::Command.new("scm_poller", [scm_poller]))
cmd.add_command(DamageControl::Process::Command.new("builder", [builder]))
cmd.add_command(DamageControl::Process::Command.new("server", [server]))
cmd.add_command(DamageControl::Process::Command.new("full", [scm_poller, builder, server]), true)

cmd.parse
