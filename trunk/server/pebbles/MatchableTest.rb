require 'test/unit'
require 'pebbles/Matchable'

class SomeMatchingClass
  include Pebbles::Matchable
  def initialize
    @some_field = "Hello World"
    @some_ignored_field = "Don't find me"
  end

private

  def matches_ignores
    ["@some_ignored_field"]
  end
end

class SomeNonMatchingClass
  include Pebbles::Matchable
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
  include Pebbles::Matchable
  def initialize
    @some_field = SomeNonMatchableClass.new
  end
end

class MatchableTest < Test::Unit::TestCase

  def test_string_matches
    assert("Hello World" =~ /orld/)
  end

  def test_custom_classes_match
    assert(SomeMatchingClass.new =~ /orld/)
    assert(!(SomeNonMatchingClass.new =~ /orld/))
  end

  def test_arrays_match
    assert(["Hello", "World"] =~ /orld/)
    assert(!(["Bonjour", "Monde"] =~ /orld/))
    assert([SomeMatchingClass.new] =~ /orld/)
  end

  def test_search_in_non_matchable_should_not_fail
    assert(!([SomeNonMatchableClass.new] =~ /orld/))
  end

  def test_search_in_non_matchable_should_not_fail
    assert(!([SomeNonMatchableClass.new] =~ /orld/))
  end

  def test_search_in_matchable_with_non_matchable_member_should_not_fail
    assert(!([SomeMatchableClassWithNonMatchableMember.new] =~ /orld/))
  end

  def test_search_in_map_searches_in_values_only
    assert({SomeNonMatchingClass.new => SomeMatchingClass.new} =~ /orld/)
    assert(!({SomeMatchingClass.new => SomeNonMatchingClass.new} =~ /orld/))
  end

  def test_ignore_fields_can_be_specified
    assert(!(SomeMatchingClass.new =~ /find me/))
  end
  
end

