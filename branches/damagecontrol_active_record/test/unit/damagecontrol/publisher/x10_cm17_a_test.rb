require File.dirname(__FILE__) + '/../../../test_helper'
require 'rscm/mockit'

module DamageControl
  module Publisher
    class X10Cm17ATest < Test::Unit::TestCase
      fixtures :builds, :projects, :revisions
      include MockIt

      if(ENV['DC_TEST_X10CM17A_ENABLE'])
        def broken_x10
          X10
        end

        def fixed_x10
          X10
        end
      else
        puts "\n"
        puts "Using mocks in #{self.class.name} (#{__FILE__})"
        puts "If you have X10Cm17a device connected you can test against real X10Cm17A devices by defining"
        puts "DC_TEST_X10CM17A_ENABLE=true in your shell"
        puts "If you have lamps connected to a1 and a2 you should see them go on and off"
        puts "\n"
        
        def broken_x10
          x10 = new_mock
          x10.__expect(:device) {|on| assert_equal("a2", on); new_mock.__expect(:on)}
          # alphabetical order of attr names
          x10.__expect(:device) {|off| assert_equal("a3", off); new_mock.__expect(:off)}
          x10.__expect(:device) {|off| assert_equal("a1", off); new_mock.__expect(:off)}
          x10
        end

        def fixed_x10
          x10 = new_mock
          x10.__expect(:device) {|on| assert_equal("a1", on); new_mock.__expect(:on)}
          # alphabetical order of attr names
          x10.__expect(:device) {|off| assert_equal("a2", off); new_mock.__expect(:off)}
          x10.__expect(:device) {|off| assert_equal("a3", off); new_mock.__expect(:off)}
          x10
        end
      end

      def test_should_turn_on_one_and_turn_off_the_rest
        x10_cm_17_a = X10Cm17A.new
        x10_cm_17_a.broken            = "a2" # red lamp
        x10_cm_17_a.executing         = "a3" # yellow lamp
        x10_cm_17_a.fixed             = "a1" # green lamp
        x10_cm_17_a.repeatedly_broken = "a2" # red lamp
        x10_cm_17_a.successful        = "a1" # green lamp

        successful        = Build.create(:exitstatus => 0, :state => Build::Successful.new)
        broken            = Build.create(:exitstatus => 1, :state => Build::Broken.new)
        fixed             = Build.create(:exitstatus => 0, :state => Build::Fixed.new)
        repeatedly_broken = Build.create(:exitstatus => 1, :state => Build::RepeatedlyBroken.new)
        executing         = Build.create(:exitstatus => nil, :state => Build::Executing.new)

        x10_cm_17_a.publish(broken, broken_x10)
        x10_cm_17_a.publish(fixed, fixed_x10)
        # can't assert success. verify manually.
      end
    end
  end
end