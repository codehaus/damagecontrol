class Time
  class << self
    def epoch
      Time.utc(1972)
    end

    def infinity
      Time.utc(2036)
    end
  end
end
