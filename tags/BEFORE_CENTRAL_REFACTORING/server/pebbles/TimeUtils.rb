# Time mixin that adds some additional utility methods
class Time
  
  # In many cases (for example when drawing a graph with 
  # dates along the x-axis) it can be useful to know what
  # month, week or day a certain timestamp is within.
  #
  # This lets you do that. Call with :day, :week or :month
  # returns period_number, period_start
  #
  # period_number is an int representing the day, week or month number of the year.
  # period_start is a utc time of the start of the period.
  def get_period_info(interval)
    case interval
      when :week then get_week_info
      when :month then get_month_info
      when :day then get_day_info
    end
  end

  # week_number, week_start_date = get_info(time, :week)
  def get_week_info
    first_day_of_year = Time.utc(utc.year, 1, 1)
    week_day_of_first_day_of_year = first_day_of_year.wday
    # Sunday = 0, .. Monday = 6
    first_monday_of_year = Time.utc(utc.year, 1, ((week_day_of_first_day_of_year % 7) + 1))

    week_number = nil
    week_start_date = nil
    days = (utc.yday - first_monday_of_year.yday)
    week_number = (days / 7) + 1
    week_start_date = first_monday_of_year + ((week_number-1) * 7) * 60 * 60 * 24
    return week_number, week_start_date
  end

  # month_number, month_start_date = get_info(time, :month)
  def get_month_info
    return month, Time.utc(utc.year, utc.month, 1)
  end

  # day_number, day_date = get_info(time, :day)
  def get_day_info
    return yday, Time.utc(utc.year, utc.month, utc.day)
  end
end