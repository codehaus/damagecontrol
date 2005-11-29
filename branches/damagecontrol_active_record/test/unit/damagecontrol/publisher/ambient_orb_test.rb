require File.dirname(__FILE__) + '/../../../test_helper'
require 'rscm/mockit'

module DamageControl
  module Publisher
    class AmbientOrbTest < Test::Unit::TestCase

      if(ENV['DC_TEST_ORB_ENABLE'])
        def driver
          Ambient::Orb.new
        end
      else
        STDERR.puts "\n"
        STDERR.puts "Using mocks in #{self.class.name} (#{__FILE__})"
        STDERR.puts "If you have an Ambient Orb device and a primary account for it you can test against real Orb devices by defining"
        STDERR.puts "DC_TEST_ORB_ENABLE=your_orb_id in your shell"
        STDERR.puts "You should see it switching to flashing green"
        STDERR.puts "\n"
        
        def driver
          driver = new_mock
          driver.__expect(:id=) {|id| assert_equal("dummy", id)}
          driver.__expect(:color=) {|color| assert_equal(:green, color)}
          driver.__expect(:animation=) {|animation| assert_equal(:medium, animation)}
          driver.__expect(:update)
          driver
        end
      end
      
      def test_should_set_flashing_yellow
        executing = builds(:build_1)
        orb_id = ENV['DC_TEST_ORB_ENABLE'] || "dummy"
        publisher = AmbientOrb.new
        publisher.orb_id = orb_id
        publisher.publish(executing, driver)
        # can't assert success. verify manually.
      end
    end
  end
end