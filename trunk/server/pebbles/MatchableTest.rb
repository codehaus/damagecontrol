require 'test/unit'
require 'pebbles/Matchable'

class SomeMatchingClass
  include Matchable
  def initialize
    @some_field = "Hello World"
  end

end

class SomeNonMatchingClass
  include Matchable
  def initialize
    @some_field = "Bonjour Monde"
  end
end

class SomeNonMatchableClass
  def initialize
    @some_field = "Hello World"
  end
end

class SomeMatchableClassWithNonMatchableMember
  include Matchable
  def initialize
    @some_field = SomeNonMatchableClass.new
  end
end

class MatchableTest < Test::Unit::TestCase

  def test_string_matches
    assert("Hello World".matches?(/orld/))
  end

  def test_custom_classes_match
    assert(SomeMatchingClass.new.matches?(/orld/))
    assert(!SomeNonMatchingClass.new.matches?(/orld/))
  end

  def test_arrays_match
    assert(["Hello", "World"].matches?(/orld/))
    assert(!["Bonjour", "Monde"].matches?(/orld/))
    assert([SomeMatchingClass.new].matches?(/orld/))
  end

  def test_search_in_non_matchable_should_not_fail
    assert(![SomeNonMatchableClass.new].matches?(/orld/))
  end

  def test_search_in_non_matchable_should_not_fail
    assert(![SomeNonMatchableClass.new].matches?(/orld/))
  end

  def test_search_in_matchable_with_non_matchable_member_should_not_fail
    assert(![SomeMatchableClassWithNonMatchableMember.new].matches?(/orld/))
  end

  def test_search_in_map_searches_in_values_only
    assert({SomeNonMatchingClass.new => SomeMatchingClass.new}.matches?(/orld/))
    assert(!{SomeMatchingClass.new => SomeNonMatchingClass.new}.matches?(/orld/))
  end

end

