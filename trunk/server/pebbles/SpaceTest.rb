require 'test/unit'
require 'timeout'
require 'pebbles/Space'

module Pebbles
  class SampleSpaceTest < Test::Unit::TestCase

    class SuperSpace < Space
      def initialize(space)
        super
        @space  = space
      end

      def on_message(o)
        # bounce it back twice as big
        @space.put("#{o}#{o}")

        # know when to stop it all
        if(o == "xxxxxxxx")
          shutdown
          @space.shutdown
        end
      end
    end

    def test_super_space_bounces_messages_back_and_forth_until_its_enough
      hub = MulticastSpace.new
      ss = SuperSpace.new(hub)
      hub.add_consumer(ss)
      
      ss.start
      
      hub.put("x")

      timeout(1) do
        hub.start.join
      end
    end
  end
end