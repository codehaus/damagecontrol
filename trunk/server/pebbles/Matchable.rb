class String
  def matches?(regexp)
    regexp.match(self)
  end
end

class Array
  def matches?(regexp)
    matches_helper(self, regexp)
  end
end

class Hash
  def matches?(regexp)
    matches_helper(values, regexp)
  end
end

module Pebbles
  module Matchable

    def matches?(regexp)
      instance_values = []
      instance_variables.each do |field_name|
        instance_values << instance_eval(field_name) unless (respond_to?("matches_ignores", true) && matches_ignores.index(field_name))
      end
      matches_helper(instance_values, regexp)
    end

  end
end

def matches_helper(array, regexp)
  array.each do |o|
    if(o.respond_to?(:matches?))
      return true if o.matches?(regexp)
    end
  end
  nil
end
