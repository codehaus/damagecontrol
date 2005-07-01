DAMAGECONTROL_HOME = File.expand_path(__FILE__ + "/../../target")

ENV["RAILS_ENV"] = "test"
require File.dirname(__FILE__) + "/../config/dc_environment"
require 'rscm/mockit'
require 'application'
require 'test/unit'
require 'active_record/fixtures'
require 'action_controller/test_process'
require 'action_web_service/test_invoke'
require 'breakpoint'

def create_fixtures(*table_names)
  Fixtures.create_fixtures(File.dirname(__FILE__) + "/fixtures", table_names)
end

Test::Unit::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
