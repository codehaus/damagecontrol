#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#
# An XML writer. The interface is based on James Clark's
# com.jclark.xml.output.XMLWriter Java class.
#

# We use @io << "foo" instead of @io.print "foo" because that way
# @io can be an IO, String, or Array.

require 'nqxml/utils'

module NQXML

    class Writer

	INDENT_OFFSET = 2

	attr_accessor :prettify

	def initialize(io, prettify = false)
	    @io = io
	    @tagNameStack = Array.new()
	    @inStartTag = false
	    @prettify = prettify
	end

	# Writes an entire tree structure out to @io.
	def writeNodeTree(node)
	    # Nodes write themselves and their children
	    node.writeTo(@io, @prettify)
	end

	# Writes a document object out to @io. Writes each of the
	# document's prolog entities, then the tree structure starting at
	# the root note.
	def writeDocument(doc)
	    doc.prolog.each { | entity |
		entity.writeXMLTo(@io, true)
		@io << "\n" if @prettify
	    }
	    writeNodeTree(doc.rootNode)
	end

	# Writes encoded version of string.
	def write(str)
	    return if str.nil? || str.empty?
	    finishStartTag() if @inStartTag
	    @io << NQXML.encode(str)
	end

	# Writes the end of a start tag.
	def finishStartTag
	    @inStartTag = false
	    @io << '>'
	    @io << "\n" if @prettify
	end

	# Starts an element. This may be followed by zero or more calls to
	# attribute. The start-tag will be closed by the first following
	# call to any method other than attribute.
	def startElement(name)
	    finishStartTag() if @inStartTag
	    @inStartTag = true
	    @tagNameStack.push(name)
	    indent() if @prettify
	    @io << "<#{name}"
	end

	# Writes an attribute. This is not legal if there have been calls
	# to methods other than attribute since the last call to
	# startElement, unless inside a startAttribute, endAttribute pair.
	def attribute(name, value)
	    if !@inStartTag
		raise WriterError.new('attribute outside of tag start')
	    end
	    @io << " #{name}=\"#{NQXML.encode(value.to_s)}\""
	end

	# Starts an attribute. This writes the attribute name, '=' and the
	# opening quote. This provides an alternative to attribute that
	# allows markup to be included in the attribute value. The value of
	# the attribute is written using the normal write methods;
	# endAttribute must be called at the end of the attribute value.
	# Entity and character references can be written using
	# entityReference and characterReference.
	def startAttribute(name)
	    if !@inStartTag
		raise WriterError.new('attribute outside of tag start')
	    end
	    @io << " #{name}=\""
	    @inStartTag = false
	end

	# Ends an attribute. This writes the closing quote of the attribute
	# value.
	def endAttribute
	    @io << '"'
	    @inStartTag = true
	end

	# Ends an element. This may output an end-tag or close the current
	# start-tag as an empty element.
	def endElement(name)
	    minimized = false

	    if @inStartTag
		@inStartTag = false
		minimized = true
		@io << '/>'
		@io << "\n" if @prettify
	    end

	    if @tagNameStack.empty?
		raise WriterError.new('end element without start element')
	    end

	    # Must indent before popping stack
	    indent() if !minimized && @prettify

	    shouldMatchName = @tagNameStack.pop()
	    if name != shouldMatchName
		raise WriterError.new("end element name #{name} does not" +
				      " match open element name " +
				      shouldMatchName)
	    end

	    if !minimized
		@io << "</#{name}>"
		@io << "\n" if @prettify
	    end
	end

	# Writes a processing instruction. If data is non-empty a space
	# will be inserted automatically to separate it from the target.
	def processingInstruction(target, data)
	    finishStartTag() if @inStartTag
	    @io << "<?#{target}"
	    @io << " #{data}" unless !data || data.empty?
	    @io << "?>"
	    @io << "\n" if @prettify
	end

	# Writes a comment.
	def comment(body)
	    finishStartTag() if @inStartTag
	    @io << "<!--#{body}-->"
	    @io << "\n" if @prettify
	end

	# Writes an entity reference.
	def entityReference(isParam, name)
	    finishStartTag() if @inStartTag
	    @io << "#{isParam ? '%' : '&'}#{name};"
	end

	# Writes a character reference. If n is a string, write the first
	# character as an integer. Else, use n.
	def characterReference(n)
	    finishStartTag() if @inStartTag
	    @io << "&\##{n.instance_of?(String) ? n[0] : n};"
	end

	# Writes a CDATA section.
	def cdataSection(content)
	    finishStartTag() if @inStartTag
	    @io << "<![CDATA[#{content}]]>"
	    @io << "\n" if @prettify
	end

	def indent
	    spaces = (@tagNameStack.length - 1) * INDENT_OFFSET
	    @io << ("\t" * (spaces >> 3)) << (' ' * (spaces & 7))
	end

    end

end
