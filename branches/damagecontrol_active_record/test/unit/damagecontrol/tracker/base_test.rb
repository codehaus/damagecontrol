require File.dirname(__FILE__) + '/../../../test_helper'

module DamageControl
  module Tracker
    class BaseTest < Test::Unit::TestCase
      def test_should_load_all
        expected = [
          Bugzilla,
          FogBugz,
          Jira,
          RubyForge,
          Scarab,
          SourceForge,
          Trac
        ]
        assert_equal(
          expected.collect{|c| c.name},
          Base.classes.collect{|c| c.name})
      end
      
      def test_should_have_at_least_two_identifier_examples
        each do |tracker|
          assert(tracker.class.identifier_examples.length > 1, tracker.class.name)
        end
      end

      def test_should_not_highlight_plain
        each do |tracker|
          assert_equal("this is plain", tracker.highlight("this is plain"))
        end
      end

      def test_should_highlight_identifier_examples
        each do |tracker|
          tracker.class.identifier_examples.each do |example|
            message = "three blind mice #{example} see how they run"
            assert_not_equal(message, tracker.highlight(message), tracker.class.name)
          end
        end
      end

    private

      def each
        Base.classes.each do |cls|
          yield cls.new
        end
      end

    end
  end
end
