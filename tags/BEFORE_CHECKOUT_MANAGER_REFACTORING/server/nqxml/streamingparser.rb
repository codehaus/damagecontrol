#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#

require 'nqxml/parser'

module NQXML

    class StreamingParser < Parser

	attr_reader :entity

	def initialize(stringOrReadable)
	    super(stringOrReadable)
	    @entity = nil
	    @lastSeenTagNameStack = nil
	    @insideProlog = nil
	end

	def each
	    @lastSeenTagNameStack = Array.new()
	    @insideProlog = true

	    @tokenizer.each { | entity |
		@entity = entity

		# Document prolog
		if @insideProlog && entity.instance_of?(Tag)
		    @insideProlog = false
		end

		if @entity.instance_of?(Tag)
		    if @entity.isTagEnd
			# Make sure stack isn't empty
			if @lastSeenTagNameStack.empty?
			    str = "end tag #{@entity.source} without opening" +
				" tag"
			    raise ParserError.new(str, @tokenizer)
			end

			# Make sure this tag name matches last seen tag
			lastSeen = @lastSeenTagNameStack.last
			if @entity.name != lastSeen
			    str = "end tag #{@entity.source} does not match" +
				" last-seen start tag name #{lastSeen}"
			    raise ParserError.new(str, @tokenizer)
			end

			@lastSeenTagNameStack.pop()
			yield(@entity)
		    else
			# Tag start
			yield(@entity)
			@lastSeenTagNameStack.push(@entity.name)
		    end
		elsif @entity.instance_of?(Comment) ||
			@entity.instance_of?(ProcessingInstruction) ||
			@entity.instance_of?(XMLDecl)
		    yield(@entity)
		elsif @entity.instance_of?(Text)
		    if @insideProlog &&
			    @entity.text =~ Tokenizer::NOT_SPACES_REGEX
			str = 'text data seen inside document prolog'
			raise ParserError.new(str, @tokenizer)
		    end
		    yield(@entity)
		elsif @entity.instance_of?(Doctype)
		    if !@insideProlog
			str = 'DOCTYPE seen outside document prolog'
			raise ParserError.new(str, @tokenizer)
		    end

		    # Send doctype
		    yield(@entity)

		    # Send entities inside doctype
		    next if @entity.entities.nil?
		    @entity.entities.each { | e |
			@entity = e
			if e.kind_of?(EntityTag) ||
				e.instance_of?(Element) ||
				e.instance_of?(Attlist) ||
				e.instance_of?(Notation) ||
				e.instance_of?(ProcessingInstruction) ||
				e.instance_of?(XMLDecl) ||
				e.instance_of?(Comment)
			    yield(e)
			else
			    str = "unknown or unexpected entity class '" +
				"#{e.class}' inside DOCTYPE tag"
			    raise ParserError.new(str, @tokenizer)
			end
		    }
		else
		    str = "unknown or unexpected entity type '" +
			"#{@entity.class}' seen"
		    raise ParserError.new(str, @tokenizer)
		end
	    }

	    # Check for remaining open tags
	    until @lastSeenTagNameStack.empty?
		name = @lastSeenTagNameStack.pop()
		str = "open tag #{name} is missing end tag"
		raise ParserError.new(str, @tokenizer)
	    end
	end

    end

end
