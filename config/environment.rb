# Be sure to restart your webserver when you modify this file.
# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

require 'optparse'
DC_ENV = {
  :data_dir => Dir.pwd
}
ARGV.options do |opts|
  opts.on("-a", "--data-dir=path", String,
      "Number of build daemons to start",
      "Default: #{DC_ENV[:data_dir]}") { |DC_ENV[:data_dir]| }
end

Rails::Initializer.run do |config|
  # See Rails::Configuration for options
  config.database_configuration_file = "#{DC_ENV[:data_dir]}/config/database.yml"
end

# Include your application configuration below
require File.join(File.dirname(__FILE__), 'dc_environment')
