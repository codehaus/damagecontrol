require 'test/unit'
require 'stringio'
require 'rscm/parser'

module RSCM
  class ParserTest < Test::Unit::TestCase
  
    class TestParser < Parser
      def initialize
        super(/^-+$/)
        @result = ""
      end
    
    protected

      def parse_line(line)
        @result << line
      end
      
      def next_result
        r = @result
        @result = ""
        r
      end
    end
  
    def test_can_parse_until_line_inclusive
      parser = TestParser.new
      io = StringIO.new(TEST_DATA)
      parser.parse(io) {|line|}
      assert_equal("one\ntwo\n", parser.parse(io))
      assert_equal("three\nfour\n", parser.parse(io))
    end

TEST_DATA = <<EOF
bla bla
--
one
two
--
three
four
--
EOF

  end
end
