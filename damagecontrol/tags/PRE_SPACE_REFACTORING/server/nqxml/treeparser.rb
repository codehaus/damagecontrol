#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#

require 'nqxml/parser'
require 'nqxml/document'

module NQXML

    class TreeParser < Parser

	def initialize(stringOrReadable)
	    super(stringOrReadable)
	    @document = Document.new()

	    # Start parsing.
	    @nodeStack = Array.new()
	    @documentSection = :DOCUMENT_PROLOG

	    @tokenizer.each { | entity | handleNextEntity(entity) }

	    # Check for remaining open tags
	    @nodeStack.reverse.each { | node |
		str = "open tag #{node.entity.name} is missing end tag"
		raise ParserError.new(str, @tokenizer)
	    }
	end

	attr_reader :document

	# Returns true if the specified entity is a comment, processing
	# instruction, XMLDecl, or whitespace.
	def miscEntity?(entity)
	    return entity.instance_of?(Comment) ||
		entity.instance_of?(ProcessingInstruction) ||
		entity.instance_of?(XMLDecl) ||
		(entity.instance_of?(Text) && (entity.text() =~ /^\s*$/m))
	end

	def handleTagStart(entity)
	    parent = @nodeStack.last
	    node = Node.new(entity, parent)

	    if parent.nil?
		# If parent is nil, we are at top level.
		if !@document.rootNode.nil?
		    str = "tag '#{entity.name}' seen after close of" +
			' top-level tag; there can only be one top-level tag'
		    raise ParserError.new(str, @tokenizer)
		end
		@document.setRootNode(node)
	    else
		parent.children << node
	    end

	    @nodeStack.push(node)
	end

	def handleTagEnd(entity)
	    # Make sure stack isn't empty
	    if @nodeStack.empty?
		str = "end tag '#{entity.name}' without opening tag"
		raise ParserError.new(str, @tokenizer)
	    end

	    # Make sure this tag name matches popped tag
	    lastSeen = @nodeStack.last
	    if entity.name != lastSeen.entity.name
		str = "end tag '#{entity.name}' does not match" +
		    " last-seen start tag named '#{lastSeen.entity.name}' "
		raise ParserError.new(str, @tokenizer)
	    end

	    @nodeStack.pop()

	    # If this is the close of the root node, we are now in the
	    # document's epilogue where only misc tags are allowed.
	    if @nodeStack.empty?
		@documentSection = :DOCUMENT_EPILOGUE
	    end
	end

	# Passes entity on to either handleTagEnd or handleTagStart. Not
	# too exciting, really.
	def handleTag(entity)
	    if entity.isTagEnd
		handleTagEnd(entity)
	    else
		handleTagStart(entity)
	    end
	end

	# Handle entity based on which document section we are in and what
	# kind of entity it is.
	def handleNextEntity(entity)
	    if @documentSection == :DOCUMENT_PROLOG
		isDocType = entity.instance_of?(Doctype)
		if !miscEntity?(entity) && !isDocType
		    @documentSection = :DOCUMENT_BODY
		    # ...continue processing this as a body tag
		else
		    if isDocType && !@document.doctype.nil?
			raise ParserError.new("multiple DOCTYPE tags seen",
					      @tokenizer)
		    end
		    @document.addToProlog(entity)
		    return
		end
	    end

	    if @documentSection == :DOCUMENT_EPILOGUE
		if !miscEntity?(entity)
		    str = "entity of type #{entity.class} seen after" +
			" document's root node"
		    raise ParserError.new(str, @tokenizer)
		end
		@document.addToEpilogue(entity)
		return
	    end

	    # We are in the body of the document.
	    if entity.instance_of?(Tag)
		handleTag(entity)
		return
	    end

	    # From here down, we have any entity except a Tag.
	    if entity.instance_of?(Doctype)
		str = 'DOCTYPE seen in document prolog'
		raise ParserError.new(str, @tokenizer)
	    end

	    # Add this entity to parent. If parent is nil, then we have a
	    # problem: the entity isn't a tag, therefore it can't be the
	    # root node.
	    parent = @nodeStack.last
	    if parent.nil?
		str = "unexpected entity of type '#{entity.class}' seen" +
		    " outside of root node"
		raise ParserError.new(str, @tokenizer)
	    end
	    parent.addChild(entity)
	end
    end

end
