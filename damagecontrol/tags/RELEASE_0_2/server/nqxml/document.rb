#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#

require 'nqxml/entities'	# Not required per se; it's here as convenience
require 'nqxml/error'		# to code that is creating documents manually.

module NQXML

    class Document
	attr_reader :prolog, :doctype, :rootNode, :epilogue

	def initialize
	    @prolog = Array.new()
	    @epilogue = Array.new()
	    @doctype = nil
	    @rootNode = nil
	end

	# Add entity to prolog. All syntax checks have already been made
	# by the parser.
	def addToProlog(entity)
	    @prolog << entity
	    if entity.instance_of?(Doctype)

		# Although this check is performed by the tree parser, we
		# check again here. The document's creation may be in the
		# hands of someone (or something) else.
		raise ParserError.new("DOCTYPE already defined") if @doctype

		@doctype = entity
	    end
	end

	# Add entity to epilogue. All syntax checks have already been made
	# by the parser.
	def addToEpilogue(entity)
	    @epilogue << entity
	end

	def setRootNode(node)
	    if node.nil?
		raise ArgumentError, 'root node may not be nil', caller
	    end

	    # Although this check is performed by the tree parser, we check
	    # again here. The document's creation may be in the hands of
	    # someone (or something) else.
	    raise ParserError.new("root node already defined") if @rootNode

	    @rootNode = node
	end

	def setRoot(entity)
	    if entity.nil?
		raise ArgumentError, 'root node may not be nil', caller
	    end

	    setRootNode(Node.new(entity, nil))
	    return @rootNode
	end

    end

    class Node
	attr_accessor :entity, :children, :parent

	def initialize(entity, parent)
	    if entity.nil?
		raise ArgumentError, "node's entity must not be nil", caller
	    end

	    @entity = entity
	    @children = Array.new()
	    @parent = parent
	end

	# Given an entity, creates a node with this entity and adds it
	# to the list of children of this node.
	def addChild(entity)
	    if entity.nil?
		raise ArgumentError, "node's entity must not be nil", caller
	    end

	    node = Node.new(entity, self)
	    @children << node
	    return node
	end

	def firstChild
	    return @children.first
	end

	def lastChild
	    return @children.last
	end

	def nextSibling
	    return nil if @parent.nil?
	    nextSib = nil
	    @parent.children.reverse.each { | sib |
		return nextSib if sib == self
		nextSib = sib
	    }
	    return nil
	end

	def prevSibling
	    return nil if @parent.nil?
	    prevSib = nil
	    @parent.children.each { | sib |
		return prevSib if sib == self
		prevSib = sib
	    }
	    return nil
	end

	# Write to io. Use the "<<" method, not print or puts, because
	# this might be a String or Array and not an IO object.
	def writeTo(io, prettify = false)
	    @entity.writeXMLTo(io, true)
	    io << "\n" if prettify
	    @children.each { | node |
		node.writeTo(io)
		io << "\n" if prettify
	    }
	    @entity.writeXMLTo(io, false)
	    io << "\n" if prettify
	end

    end

end
