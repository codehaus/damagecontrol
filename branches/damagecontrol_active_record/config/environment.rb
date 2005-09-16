# Be sure to restart your webserver when you modify this file.
# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # See Rails::Configuration for options
  
  # SHELL_DIR is used in config/database.yml
  SHELL_DIR = File.expand_path(Dir.pwd) unless defined? SHELL_DIR
  if defined? DC_ENV
    raise "DC_ENV was defined, but had no :database_yml key" unless DC_ENV[:database_yml]
    config.database_configuration_file = DC_ENV[:database_yml] 
  end
end

# Include your application configuration below
require File.join(File.dirname(__FILE__), 'dc_environment')
