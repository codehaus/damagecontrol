require 'test/unit'
require 'rscm/tempdir'
require 'rscm/difftool'
require 'rscm/path_converter'

module RSCM

  class DifftoolTest < Test::Unit::TestCase
    include Difftool

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