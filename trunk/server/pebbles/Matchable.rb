class Array
  def =~(regexp)
    first_match(self, regexp)
  end
end

class Hash
  def =~(regexp)
    first_match(values, regexp)
  end
end

module Pebbles
  module Matchable

    # TODO: rename to =~
    def =~ regexp
      instance_values = []
      instance_variables.each do |field_name|
        instance_values << instance_eval(field_name) unless (respond_to?("matches_ignores", true) && matches_ignores.index(field_name))
      end
      first_match(instance_values, regexp)
    end

  end
end

def first_match(array, regexp)
  array.each do |o|
    result = o =~(regexp)
    return result if result
  end
  nil
end
