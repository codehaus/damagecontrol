require 'fileutils'
if(ENV['RAILS_ENV'] == "production")
  raise "The environment variable DC_DATA_DIR must be defined and point to the directory where DamageControl will store data." unless ENV['DC_DATA_DIR']
  DC_DATA_DIR = File.expand_path(ENV['DC_DATA_DIR'])
else
  DC_DATA_DIR = File.expand_path("target/data")
end
FileUtils.mkdir_p "#{DC_DATA_DIR}/db" unless File.exist?("#{DC_DATA_DIR}/db")
FileUtils.mkdir_p "#{DC_DATA_DIR}/log" unless File.exist?("#{DC_DATA_DIR}/log")
