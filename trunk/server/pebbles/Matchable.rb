#
# Author: Aslak Hellesoy
#
class Array
  def =~(regexp)
    matches?(self, regexp)
  end
end

class Hash
  def =~(regexp)
    matches?(values, regexp)
  end
end

module Pebbles
  #
  # Including this mixin in a class will allow regexp matching against all fields' values of instances of that class.
  #
  # Classes including this mixin may optionally implement a private method called matches_ignores
  # if some fields should not be matched against. This method should return an array of all field 
  # names that should not be matched against. Example:
  #
  # def matches_ignores
  #   ["@dont_match_me", "@dont_match_me_either"]
  # end
  #
  module Matchable

    def =~(regexp)
      instance_values = []
      instance_variables.each do |field_name|
        instance_values << instance_eval(field_name) unless (respond_to?("matches_ignores", true) && matches_ignores.index(field_name))
      end
      matches?(instance_values, regexp)
    end

  end
end

def matches?(array, regexp)
  array.each do |o|
    return true if(o =~(regexp))
  end
  false
end
