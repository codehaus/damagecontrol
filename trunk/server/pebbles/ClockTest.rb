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
      t = Countdown.new(2)
      def t.tick(time)
        @r = 0 unless @r
        @r += 1
      end

      def t.r
        @r
      end

      timeout(6) do
        t.start
        t.start
        t.start
        sleep(1)
        t.start
        sleep(3)
      end
      
      assert_equal(1, t.r)
    end
    
    def test_clock
      t = Clock.new(1)
      def t.tick(time)
        @r = 0 unless @r
        @r += 1
      end

      def t.r
        @r
      end

      timeout(6) do
        t.start
        sleep(5)
      end
      assert_equal(4, t.r)
      t.shutdown
    end
  end
end