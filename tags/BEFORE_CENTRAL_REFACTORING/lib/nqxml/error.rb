#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#

module NQXML

    class ParserError < RuntimeError

	attr_reader :line, :column, :pos

	# We don't have to "require 'nqxml/tokenizer' because I don't really
	# care if it is an NQXML::Tokenizer. All I really care is that
	# the argument responds to line(), column(), and pos().
	def initialize(message, readStream)
	    super(message)
	    @line = readStream.respond_to?(:line) ? readStream.line() : -1
	    @column = readStream.respond_to?(:column) ? readStream.column() :
		-1
	    @pos = readStream.respond_to?(:pos) ? readStream.pos() : -1
	end
    end

    class WriterError < RuntimeError
    end
end
