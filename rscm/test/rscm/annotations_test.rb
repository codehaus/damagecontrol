require 'test/unit'
require 'rscm/annotations'

module RSCM
  class Whatever
    attr_accessor :no_annotations

    ann :boo => "huba luba", :pip => "pip pip"
    attr_accessor :foo
  
    ann :desc => "bang bang"
    ann :tip => "a top tip"
    attr_accessor :bar, :zap
  end

  class AnnotationsTest < Test::Unit::TestCase
    def test_should_allow_attr_attr_description
      assert_equal("huba luba", Whatever.foo[:boo])
      assert_equal("pip pip", Whatever.foo[:pip])

      assert_nil(Whatever.bar[:pip])
      assert_equal("bang bang", Whatever.bar[:desc])
      assert_equal("a top tip", Whatever.bar[:tip])

      assert_equal("bang bang", Whatever.zap[:desc])
      assert_equal("a top tip", Whatever.zap[:tip])
    end
  end
end
