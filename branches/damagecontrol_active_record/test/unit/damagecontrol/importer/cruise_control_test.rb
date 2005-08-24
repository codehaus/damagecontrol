require File.dirname(__FILE__) + '/../../../test_helper'

module DamageControl
  module Importer
    class CruiseControlTest < Test::Unit::TestCase
      
      def test_should_import_from_xml
        File.open(File.dirname(__FILE__) + "/cruise_control_config.xml") do |io|
          project = Project.create
          project.import_from_cruise_control(io)
          assert_equal "Mooky", project.name
        end
      end
    end
  end
end