require 'test/unit'
require 'rscm/annotations'

module RSCM
  class Whatever
    attr_accessor :no_annotation
    ann :boo => "huba luba", :pip => "pip pip"
    attr_accessor :foo
  
    ann :desc => "bang bang"
    ann :tip => "a top tip"
    attr_accessor :bar, :zap
  end

  class Other
    attr_accessor :no_annotation
    ann :boo => "boo"
    ann :pip => "pip"
    attr_accessor :foo
  
    ann :desc => "desc", :tip => "tip"
    attr_accessor :bar, :zap
  end

  class AnnotationsTest < Test::Unit::TestCase
    def test_should_handle_annotations_really_well
      assert_equal("huba luba", Whatever.foo[:boo])
      assert_equal("pip pip", Whatever.foo[:pip])

      assert_nil(Whatever.bar[:pip])
      assert_equal("bang bang", Whatever.bar[:desc])
      assert_equal("a top tip", Whatever.bar[:tip])

      assert_equal("bang bang", Whatever.zap[:desc])
      assert_equal("a top tip", Whatever.zap[:tip])

      assert_nil(Whatever.barf[:pip])

      assert_equal("boo", Other.foo[:boo])
      assert_equal("pip", Other.foo[:pip])

      assert_nil(Whatever.bar[:pip])
      assert_equal("desc", Other.bar[:desc])
      assert_equal("tip", Other.bar[:tip])

      assert_equal("desc", Other.zap[:desc])
      assert_equal("tip", Other.zap[:tip])

    end
  end
end
