module RSCM
  module TimeExt
    SECOND =   1
    MINUTE =  60
    HOUR   =  60 * MINUTE
    DAY    =  24 * HOUR
    WEEK   =   7 * DAY
    MONTH  =  30 * DAY
    YEAR   = 365 * DAY
    YEARS  =   2 * YEAR

    def duration_as_text(duration_secs)
      case duration_secs
        when 0                   then "0 seconds"
        when SECOND              then "#{duration_secs/SECOND} second"
        when SECOND+1..MINUTE-1  then "#{duration_secs/SECOND} seconds"
        when MINUTE..2*MINUTE-1  then "#{duration_secs/MINUTE} minute"
        when 2*MINUTE..HOUR-1    then "#{duration_secs/MINUTE} minutes"
        when HOUR..2*HOUR-1      then "#{duration_secs/HOUR} hour"
        when 2*HOUR..DAY-1       then "#{duration_secs/HOUR} hours"
        when DAY..2*DAY-1        then "#{duration_secs/DAY} day"
        when 2*DAY..WEEK-1       then "#{duration_secs/DAY} days"
        when WEEK..2*WEEK-1      then "#{duration_secs/WEEK} week"
        when 2*WEEK..MONTH-1     then "#{duration_secs/WEEK} weeks"
        when MONTH..2*MONTH-1    then "#{duration_secs/MONTH} month"
        when 2*MONTH..YEAR-1     then "#{duration_secs/MONTH} months"
        when YEAR..2*YEAR-1      then "#{duration_secs/YEAR} year"
        else                          "#{duration_secs/YEAR} years"
      end
    end
    module_function :duration_as_text
  end
end

# Time mixin that adds some additional utility methods
class Time
  include RSCM::TimeExt
  
  def Time.parse_ymdHMS(timestamp_as_ymdHMS)
    begin
      Time.utc(
        timestamp_as_ymdHMS[0..3], # year 
        timestamp_as_ymdHMS[4..5], # month
        timestamp_as_ymdHMS[6..7], # day
        timestamp_as_ymdHMS[8..9], # hour
        timestamp_as_ymdHMS[10..11], # minute
        timestamp_as_ymdHMS[12..13] # second
      )
    rescue Exception => e
      puts e.message
      puts e.backtrace.join("\n")
      nil
    end
  end
  
  def to_rfc2822
    utc.strftime("%a, %d %b %Y %H:%M:%S +0000")
  end
  
  def to_human
    utc.strftime("%d %b %Y %H:%M:%S")
  end
  
  def ymdHMS
    utc.strftime("%Y%m%d%H%M%S")
  end
  
  def ==(o)
    return false unless o.is_a?(Time)
    ymdHMS == o.ymdHMS
  end

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

  def difference_as_text(t)
    raise "t must be a time" unless t.is_a?(Time)
    diff = (self - t).to_i
    duration_as_text(diff)
  end

end
