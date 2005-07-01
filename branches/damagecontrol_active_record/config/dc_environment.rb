require File.dirname(__FILE__) + '/environment'

# TODO: fix when we start using gem RSCM
$:.unshift("../../trunk/rscm/lib")
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

def create_logger(cls)
  log_name = Inflector.underscore(Inflector.demodulize(cls.name))
  log_file = "#{DAMAGECONTROL_HOME}/log/#{log_name}.log"
  dir = File.dirname(log_file)
  FileUtils.mkdir_p(dir) unless File.exist?(dir)
  Logger.new(log_file)
end

# TODO: Ues thread-specific loggers - easier to follow
[DamageControl::ScmPoller, Build, Project, Publisher, Revision].each { |cls| cls.logger = create_logger(cls) }
