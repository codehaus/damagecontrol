require 'test/unit'
require 'pebbles/TimeUtils'

class TimeUtilsTest < Test::Unit::TestCase

  def test_difference_as_text
    assert_equal("0 seconds",                  Time.utc(2003,01,01,00,00,00).difference_as_text(Time.utc(2003,01,01,00,00,00)))

    assert_equal("1 second",                   Time.utc(2003,01,01,00,00,01).difference_as_text(Time.utc(2003,01,01,00,00,00)))
    assert_equal("2 seconds",                  Time.utc(2003,01,01,00,00,02).difference_as_text(Time.utc(2003,01,01,00,00,00)))
    assert_equal("59 seconds",                 Time.utc(2003,01,01,00,00,59).difference_as_text(Time.utc(2003,01,01,00,00,00)))

    assert_equal("1 minute",                   Time.utc(2003,01,01,00,01,00).difference_as_text(Time.utc(2003,01,01,00,00,00)))
    assert_equal("1 minute",                   Time.utc(2003,01,01,00,01,59).difference_as_text(Time.utc(2003,01,01,00,00,00)))
    assert_equal("2 minutes",                  Time.utc(2003,01,01,00,02,00).difference_as_text(Time.utc(2003,01,01,00,00,00)))
    assert_equal("59 minutes",                 Time.utc(2003,01,01,00,59,59).difference_as_text(Time.utc(2003,01,01,00,00,00)))

    assert_equal("1 hour",                     Time.utc(2003,01,01,01,00,00).difference_as_text(Time.utc(2003,01,01,00,00,00)))
    assert_equal("1 hour",                     Time.utc(2003,01,01,01,59,59).difference_as_text(Time.utc(2003,01,01,00,00,00)))
    assert_equal("2 hours",                    Time.utc(2003,01,01,02,00,00).difference_as_text(Time.utc(2003,01,01,00,00,00)))
    assert_equal("23 hours",                   Time.utc(2003,01,01,23,59,59).difference_as_text(Time.utc(2003,01,01,00,00,00)))

    assert_equal("1 day",                      Time.utc(2003,01,02,00,00,00).difference_as_text(Time.utc(2003,01,01,00,00,00)))
    assert_equal("1 day",                      Time.utc(2003,01,02,23,59,59).difference_as_text(Time.utc(2003,01,01,00,00,00)))
    assert_equal("2 days",                     Time.utc(2003,01,03,00,00,00).difference_as_text(Time.utc(2003,01,01,00,00,00)))
    assert_equal("6 days",                     Time.utc(2003,01,07,23,59,59).difference_as_text(Time.utc(2003,01,01,00,00,00)))

    assert_equal("1 week",                     Time.utc(2003,01, 8,00,00,00).difference_as_text(Time.utc(2003,01,01,00,00,00)))
    assert_equal("1 week",                     Time.utc(2003,01,14,23,59,59).difference_as_text(Time.utc(2003,01,01,00,00,00)))
    assert_equal("2 weeks",                    Time.utc(2003,01,15,00,00,00).difference_as_text(Time.utc(2003,01,01,00,00,00)))
    assert_equal("4 weeks",                    Time.utc(2003,01,30,23,59,59).difference_as_text(Time.utc(2003,01,01,00,00,00)))

    assert_equal("1 month",                    Time.utc(2003,01,31,00,00,00).difference_as_text(Time.utc(2003,01,01,00,00,00)))
    assert_equal("1 month",                    Time.utc(2003,03,01,23,59,59).difference_as_text(Time.utc(2003,01,01,00,00,00)))
    assert_equal("2 months",                   Time.utc(2003,03,02,00,00,00).difference_as_text(Time.utc(2003,01,01,00,00,00)))
    assert_equal("12 months",                  Time.utc(2003,12,31,23,59,59).difference_as_text(Time.utc(2003,01,01,00,00,00)))

    assert_equal("1 year",                     Time.utc(2004,01,01,00,00,00).difference_as_text(Time.utc(2003,01,01,00,00,00)))
    # leap year not handled, but that's ok
    assert_equal("1 year",                     Time.utc(2004,12,30,23,59,59).difference_as_text(Time.utc(2003,01,01,00,00,00)))
    assert_equal("2 years",                    Time.utc(2004,12,31,00,00,00).difference_as_text(Time.utc(2003,01,01,00,00,00)))
  end

end
