module Pebbles
  class Clock
    attr_reader :exception
  
    def initialize(seconds, callback=self)
      @seconds = seconds
      @callback = callback
      @run = true
    end

    def start
      shutdown
      @run = true
      return increase if @seconds == 0
      @sleeper = Thread.new do
        while(@run)
          sleep @seconds
          begin
            increase
          rescue Exception => e
            @callback.exception(e)
          end
        end
      end
    end
    
    def shutdown
      @run = false
      @sleeper.kill if @sleeper and @sleeper.alive?
    end
    
    def tick(time)
    end
    
    def exception(e)
      puts e
      puts e.backtrace.join("\n")
    end

  protected

    def increase
      @callback.tick(Time.new.utc)
    end

  end
  
  class Countdown < Clock
    def increase
      super
      shutdown
    end
  end
end

if __FILE__ == $0
  require 'test/unit'
  require 'timeout'

  class CountdownTest < Test::Unit::TestCase # :nodoc:
    include Pebbles

    def test_countdown
      t = Countdown.new(2)
      def t.tick
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
      def t.tick
        @r = 0 unless @r
        @r += 1
        puts @r
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
