require 'test/unit'
require 'timeout'
require 'pebbles/Space'

module Pebbles
  class SpaceAcceptanceTest < Test::Unit::TestCase

    class Blocker < Space
      attr_reader :delivered_messages
      attr_reader :in_queue
    
      def initialize
        super
        @delivered_messages = []
      end
      
      def on_message(o)
        @delivered_messages << o
        sleep(1)
      end
    end

    def test_messages_are_delivered_asynchronously
      # set up a hub that broadcasts to two slow components
      hub = MulticastSpace.new
      a = hub.add_consumer(Blocker.new)
      b = hub.add_consumer(Blocker.new)

      # add message should be instant when idle
      timeout(1) do
        hub.add("three")
        hub.add("blind")
        hub.add("mice")
      end
      assert_equal(0, a.in_queue.length)
      assert_equal(0, b.in_queue.length)
      assert_equal([], a.delivered_messages)
      assert_equal([], b.delivered_messages)

      hub_waiter = Thread.new do
        hub.start.join
      end
      a.start
      sleep 4
      assert_equal(0, a.in_queue.length)
      assert_equal(3, b.in_queue.length)
      assert_equal(["three", "blind", "mice"], a.delivered_messages)
      assert_equal([], b.delivered_messages)

      b.start
      sleep 4
      assert_equal(0, a.in_queue.length)
      assert_equal(0, b.in_queue.length)
      assert_equal(["three", "blind", "mice"], a.delivered_messages)
      assert_equal(["three", "blind", "mice"], b.delivered_messages)

      hub.shutdown
      hub_waiter.join(2)
    end

  end
end