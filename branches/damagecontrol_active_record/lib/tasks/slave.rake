# Builds the slave
require 'damagecontrol/platform'
include DamageControl::Platform

desc "Builds the Java build slave"
task :slave do
  Dir.chdir(RAILS_ROOT + '/java') do
    family == "mswin32" ? `ant.bat` : `ant`
  end
end