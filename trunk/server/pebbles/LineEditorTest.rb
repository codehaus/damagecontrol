require 'stringio'
require 'ftools'
require 'test/unit'
require 'pebbles/LineEditor'

module Pebbles
  class LineEditorTest < Test::Unit::TestCase

    include Pebbles::LineEditor

ORIGINAL_FILE = <<-EOF
dette er en helt
alminnelig fil med et
# denne er allerede utkommentert
som vi skal editere
EOF

ORIGINAL_FILE_WITH_HASH_STYLE_COMMENT = <<-EOF
# dette er en helt
alminnelig fil med et
# denne er allerede utkommentert
# som vi skal editere
EOF

ORIGINAL_FILE_WITH_DELETED_LINES = <<-EOF
alminnelig fil med et
EOF

    def test_should_comment_out_matching_lines_with_hash
      original = StringIO.new(ORIGINAL_FILE)
      output = ""
      assert(comment_out(original, /er/, "# ", output))
      assert(!comment_out(original, /not in file/, "# ", output))
      assert_equal(ORIGINAL_FILE_WITH_HASH_STYLE_COMMENT, output)
    end

    def test_should_delete_matching_lines
      original = StringIO.new(ORIGINAL_FILE)
      output = ""
      assert(comment_out(original, /er/, nil, output))
      assert_equal(ORIGINAL_FILE_WITH_DELETED_LINES, output)
    end
    
    def test_should_delete_matching_lines_in_file
      File.copy("testdata/file_to_edit", "testdata/file_to_edit.copy")
      assert(File.comment_out("testdata/file_to_edit.copy", /er/, nil))
      expected = nil
      File.open("testdata/file_after_edit") {|file| expected = file.read}
      actual = nil
      File.open("testdata/file_to_edit.copy") {|file| actual = file.read}
      assert_equal(expected, actual)
    end
  end
end
