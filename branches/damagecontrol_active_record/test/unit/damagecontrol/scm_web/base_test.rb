require File.dirname(__FILE__) + '/../../../test_helper'

module DamageControl
  module ScmWeb
    class BaseTest < Test::Unit::TestCase
      def test_should_load_all_publisher_classes
        expected = [
          Chora,
          DamageControl,
          Fisheye,
          Trac,
          ViewCvs
        ]
        assert_equal(
          expected.collect{|c| c.name},
          Base.classes.collect{|c| c.name})
      end
    end
  end
end
