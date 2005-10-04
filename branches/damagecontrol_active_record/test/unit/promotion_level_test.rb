require File.dirname(__FILE__) + '/../test_helper'

class PromotionLevelTest < Test::Unit::TestCase
  fixtures :promotion_levels

  def setup
    @promotion_level = PromotionLevel.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of PromotionLevel,  @promotion_level
  end
end
