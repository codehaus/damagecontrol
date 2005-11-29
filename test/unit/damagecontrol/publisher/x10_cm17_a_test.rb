require File.dirname(__FILE__) + '/../../../test_helper'
require 'rscm/mockit'

module DamageControl
  module Publisher
    class X10Cm17ATest < Test::Unit::TestCase

      if(ENV['DC_TEST_X10CM17A_ENABLE'])
        def broken_x10
          X10
        end

        def fixed_x10
          X10
        end
      else
        STDERR.puts "\n"
        STDERR.puts "Using mocks in #{self.class.name} (#{__FILE__})"
        STDERR.puts "If you have X10Cm17a device connected you can test against real X10Cm17A devices by defining"
        STDERR.puts "DC_TEST_X10CM17A_ENABLE=true in your shell"
        STDERR.puts "If you have lamps connected to a5 and a6 you should see them go on and off"
        STDERR.puts "\n"
        
        def fixed_x10
          x10 = new_mock
          x10.__expect(:device) {|on| assert_equal("a5", on); new_mock.__expect(:on)}
          # alphabetical order of attr names
          x10.__expect(:device) {|off| assert_equal("a1", off); new_mock.__expect(:off)}
          x10.__expect(:device) {|off| assert_equal("a2", off); new_mock.__expect(:off)}
          x10.__expect(:device) {|off| assert_equal("a3", off); new_mock.__expect(:off)}
          x10.__expect(:device) {|off| assert_equal("a4", off); new_mock.__expect(:off)}
          x10.__expect(:device) {|off| assert_equal("a6", off); new_mock.__expect(:off)}
          x10.__expect(:device) {|off| assert_equal("a7", off); new_mock.__expect(:off)}
          x10
        end

        def broken_x10
          x10 = new_mock
          x10.__expect(:device) {|on| assert_equal("a6", on); new_mock.__expect(:on)}
          # alphabetical order of attr names
          x10.__expect(:device) {|off| assert_equal("a1", off); new_mock.__expect(:off)}
          x10.__expect(:device) {|off| assert_equal("a2", off); new_mock.__expect(:off)}
          x10.__expect(:device) {|off| assert_equal("a3", off); new_mock.__expect(:off)}
          x10.__expect(:device) {|off| assert_equal("a4", off); new_mock.__expect(:off)}
          x10.__expect(:device) {|off| assert_equal("a5", off); new_mock.__expect(:off)}
          x10.__expect(:device) {|off| assert_equal("a7", off); new_mock.__expect(:off)}
          x10
        end

      end

      def test_should_turn_on_one_and_turn_off_the_rest
        x10_cm_17_a = X10Cm17A.new

        fixed             = builds(:build_1)
        broken            = builds(:build_2)

        x10_cm_17_a.publish(fixed, fixed_x10)
        x10_cm_17_a.publish(broken, broken_x10)
        # can't assert success. verify manually.
      end
    end
  end
end