require File.dirname(__FILE__) + '/../../../test_helper'
require 'rscm/mockit'

module DamageControl
  module Publisher
    class AmbientOrbTest < Test::Unit::TestCase
      fixtures :builds, :projects, :revisions
      include MockIt

      if(ENV['DC_TEST_ORB_ENABLE'])
        def driver
          Ambient::Orb.new
        end
      else
        puts "\n"
        puts "Using mocks in #{self.class.name} (#{__FILE__})"
        puts "If you have an Ambient Orb device and a primary account for it you can test against real Orb devices by defining"
        puts "DC_TEST_ORB_ENABLE=your_orb_id in your shell"
        puts "You should see it switching to flashing yellow"
        puts "\n"
        
        def driver
          driver = new_mock
          driver.__expect(:id=) {|id| assert_equal("dummy", id)}
          driver.__expect(:color=) {|color| assert_equal(:yellow, color)}
          driver.__expect(:animation=) {|animation| assert_equal(:medium, animation)}
          driver.__expect(:update)
          driver
        end
      end

      def test_should_set_flashing_yellow
        orb_id = ENV['DC_TEST_ORB_ENABLE'] || "dummy"
        publisher = AmbientOrb.new
        publisher.orb_id = orb_id
        executing = Build.create(:exitstatus => nil, :state => Build::Executing.new)
        publisher.publish(executing, driver)
        # can't assert success. verify manually.
      end
    end
  end
end