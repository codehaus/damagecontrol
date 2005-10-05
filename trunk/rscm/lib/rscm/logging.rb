require 'rscm/path_converter'
require 'logger'

if(WINDOWS)
  HOMEDIR = RSCM::PathConverter.nativepath_to_filepath("#{ENV['HOMEDRIVE']}#{ENV['HOMEPATH']}").gsub(/\\/, "/")
else
  HOMEDIR = ENV['HOME']
end
