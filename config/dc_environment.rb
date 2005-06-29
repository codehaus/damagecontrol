# Set DAMAGECONTROL_HOME if it hasn't already been set
require 'rscm'
if(!ENV['DAMAGECONTROL_HOME'])
  if(WINDOWS)
    ENV['DAMAGECONTROL_HOME'] = 
      RSCM::PathConverter.nativepath_to_filepath("#{ENV['HOMEDRIVE']}#{ENV['HOMEPATH']}/.damagecontrol").gsub(/\\/, "/")
  else
    ENV['DAMAGECONTROL_HOME'] = 
      "#{ENV['HOME']}/.damagecontrol"
  end
end
$stderr.puts "DAMAGECONTROL_HOME => #{ENV['DAMAGECONTROL_HOME']}"
