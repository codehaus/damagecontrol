require 'test/unit'
require 'pebbles/LifecycleContainer'

module Pebbles

  class Foo
    def initialize
      @started = false
    end

    def start
      @started = true
    end

    def shutdown
      @started = false
    end

    def started?
      @started
    end

  end

  class Bar < Foo
    include Test::Unit::Assertions

    def initialize(foo)
      assert_equal(Foo, foo.class)
    end
  end

  class LifecycleContainerTest < Test::Unit::TestCase

    def test_components_can_be_assembled_with_nice_syntax_and_lifecycled
      lc = LifecycleContainer.new {
        component(:foo, Foo.new),
        component(:bar, Bar.new(foo))
      }
      
      assert(!lc.foo.started?)
      assert(!lc.bar.started?)
      lc.start
      assert(lc.foo.started?)
      assert(lc.bar.started?)
      lc.shutdown
      assert(!lc.foo.started?)
      assert(!lc.bar.started?)
    end
    
  end
end