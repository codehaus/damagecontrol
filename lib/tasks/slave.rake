desc "Builds the Java build slave"
task :slave do
  require 'rscm/platform'
  Dir.chdir(RAILS_ROOT + '/java') do
    RSCM::Platform.family == "mswin32" ? `ant.bat` : `ant`
  end
end