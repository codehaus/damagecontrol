require File.dirname(__FILE__) + '/environment'

require 'damagecontrol'
unless defined? DAMAGECONTROL_HOME
  if(ENV['DAMAGECONTROL_HOME'])
    DAMAGECONTROL_HOME = ENV['DAMAGECONTROL_HOME']
  else
    if(WINDOWS)
      DAMAGECONTROL_HOME = 
        RSCM::PathConverter.nativepath_to_filepath("#{ENV['HOMEDRIVE']}#{ENV['HOMEPATH']}/.damagecontrol").gsub(/\\/, "/")
    else
      DAMAGECONTROL_HOME = 
        "#{ENV['HOME']}/.damagecontrol"
    end
  end
end

begin
  DAMAGECONTROL_DEFAULT_LOGGER = Logger.new("#{DAMAGECONTROL_HOME}/log/damagecontrol.log")
rescue StandardError
  DAMAGECONTROL_DEFAULT_LOGGER = Logger.new(STDERR)
  DAMAGECONTROL_DEFAULT_LOGGER.level = Logger::WARN
  DAMAGECONTROL_DEFAULT_LOGGER.warn(
    "Rails Error: Unable to access log file. Please ensure that #{DAMAGECONTROL_HOME}/log/damagecontrol.log exists and is chmod 0666. " +
    "The log level has been raised to WARN and the output directed to STDERR until the problem is fixed."
  )
end

[DamageControl::ScmPoller].each { |cls| cls.logger ||= DAMAGECONTROL_DEFAULT_LOGGER }
