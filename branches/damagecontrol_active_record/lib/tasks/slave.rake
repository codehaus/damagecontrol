# Builds the slave

task :slave do
  Dir.chdir(RAILS_ROOT + '/java') do
    `ant.bat`
  end
end