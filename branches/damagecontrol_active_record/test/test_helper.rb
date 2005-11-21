ENV["RAILS_ENV"] = "test"
require 'file_wiper'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class Test::Unit::TestCase
  fixtures :artifacts, :build_executors, :build_executors_projects, :builds, :projects, :promotion_levels, :revision_files, :revisions, :poll_requests
  
  # Turn off transactional fixtures if you're working with MyISAM tables in MySQL
  self.use_transactional_fixtures = true
  
  # Instantiated fixtures are slow, but give you @david where you otherwise would need people(:david)
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
end