require 'test/unit'
require 'rscm/tempdir'

module Test
  module Unit
    class TestCase
      # assertion method that reports differences as diff.
      # useful when comparing big strings
      def assert_equal_with_diff(expected, actual)
        dir = RSCM.new_temp_dir("diff")
        File.open("#{dir}/expected", "w") {|io| io.write(expected)}
        File.open("#{dir}/actual", "w") {|io| io.write(actual)}

        IO.popen("diff #{dir}/expected #{dir}/actual") do |io|
          diff = io.read
          assert_equal("", diff, diff)
        end
      end
    end
  end
end

module RSCM
  class DiffPersisterTest < Test::Unit::TestCase
    def test_diffing_fails_with_diff_when_different
      assert_raises(Test::Unit::AssertionFailedError) {
        assert_equal_with_diff("This is a\nmessage with\nsome text", "This is a\nmessage without\nsome text")
      }
    end

    def test_diffing_passes_with_diff_when_equal
      assert_equal_with_diff("This is a\nmessage with\nsome text", "This is a\nmessage with\nsome text")
    end
  end
end