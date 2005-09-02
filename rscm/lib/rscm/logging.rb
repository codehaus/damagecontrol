require 'rscm/path_converter'
require 'logger'

if(WINDOWS)
  HOMEDIR = RSCM::PathConverter.nativepath_to_filepath("#{ENV['HOMEDRIVE']}#{ENV['HOMEPATH']}").gsub(/\\/, "/")
else
  HOMEDIR = ENV['HOME']
end

begin
  RSCM_DEFAULT_LOGGER = Logger.new("#{HOMEDIR}/.rscm.log")
rescue StandardError
  RSCM_DEFAULT_LOGGER = Logger.new(STDERR)
  RSCM_DEFAULT_LOGGER.level = Logger::WARN
  RSCM_DEFAULT_LOGGER.warn(
    "RSCM Error: Unable to access log file. Please ensure that #{HOMEDIR}/.rscm.log exists and is chmod 0666. " +
    "The log level has been raised to WARN and the output directed to STDERR until the problem is fixed."
  )
end
