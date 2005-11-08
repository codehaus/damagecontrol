# Builds the slave (Java app)
require 'damagecontrol/platform'

desc "Builds the Java build slave"
task :slave do
  Dir.chdir(RAILS_ROOT + '/java') do
    DamageControl::Platform.family == "mswin32" ? `ant.bat` : `ant`
  end
end