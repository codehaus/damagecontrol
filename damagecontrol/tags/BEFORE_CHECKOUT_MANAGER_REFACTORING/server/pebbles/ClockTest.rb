require 'test/unit'
require 'timeout'
require 'pebbles/Clock'

module Pebbles

  class CountdownTest < Test::Unit::TestCase # :nodoc:
    include Pebbles
    
    def test_time_left
      t = Countdown.new(5)
      timeout(6) do
        t.start
        sleep 1
        assert("incorrect time left: #{t.time_left}", t.time_left < 4)
        assert("incorrect time left: #{t.time_left}", t.time_left > 2)
        sleep 2
        assert("incorrect time left: #{t.time_left}", t.time_left < 2)
        assert("incorrect time left: #{t.time_left}", t.time_left > 0)
      end
    end

    def test_countdown
      r = 0
      t = Countdown.new(2) do |time|
        r += 1
      end

      timeout(6) do
        t.start
        t.start
        t.start
        sleep(1)
        t.start
        sleep(3)
      end
      
      assert_equal(1, r)
    end
    
    def test_clock_ticks_several_times
      r = 0
      t = Clock.new(1) do |time|
        r += 1
      end

      begin
        timeout(3, TimeoutError) do
          t.start
          sleep(3)
        end
      rescue TimeoutError => e
        #expected
      end
      assert(r >= 2)
      t.shutdown
    end
  end
end