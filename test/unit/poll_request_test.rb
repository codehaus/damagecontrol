require File.dirname(__FILE__) + '/../test_helper'

class PollRequestTest < Test::Unit::TestCase
  fixtures :poll_requests

  # Replace this with your real tests.
  def test_truth
    assert_kind_of PollRequest, poll_requests(:first)
  end
end
