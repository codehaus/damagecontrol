#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#

require 'nqxml/error'		# Used by all subclasses, so required here
require 'nqxml/tokenizer'

module NQXML

    class Parser

	def initialize(stringOrReadable)
	    @tokenizer = Tokenizer.new(stringOrReadable)
	end

	def eof?
	    return @tokenizer.eof?()
	end
	alias_method :atEnd, :eof?
	alias_method :eof, :eof?
    end

end
