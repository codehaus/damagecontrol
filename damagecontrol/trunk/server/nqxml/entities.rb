#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#

require 'nqxml/utils'

module NQXML

    # The abstract base class of almost all XML entites.
    class Entity

	attr_reader :source

	def initialize(source=nil)
	    @source = source
	end

	def to_s
	    return @source ? @source : ''
	end

	def ==(anObj)
	    return anObj.instance_of?(self.class) &&
		@source == anObj.source
	end

	# Write XML to io. Use the "<<" method, not print or puts, because
	# this might be a String or Array and not an IO object.
	def writeXMLTo(io, beforeChildren=true)
	    io << self.to_s if beforeChildren
	end
    end

    # An abstract superclass for entities with names.
    class NamedEntity < Entity

	attr_reader :name

	def initialize(name, source=nil)
	    super(source)
	    @name = name
	end

	def ==(anObj)
	    return super(anObj) &&
		@name == anObj.name
	end
    end

    # An abstract superclass for entities with names and attributes.
    class NamedAttributes < NamedEntity
	attr_reader :attrs

	def initialize(name, attrs, source=nil)
	    super(name, source)
	    @attrs = attrs
	end

	def ==(anObj)
	    return super(anObj) &&
		@attrs == anObj.attrs
	end

	# Returns a string containing the attribute key/value pairs as XML.
	# Values are encoded.
	def attributesToXML
	    return '' if @attrs.nil?
	    str = ''
	    @attrs.each { | key, val |
		str << " #{key}=\"#{NQXML.encode(val.to_s)}\""
	    }
	    return str
	end

	# Returns a string containing the attribute key/value pairs as
	# a simple, unencoded string.
	def attributesToString
	    return '' if @attrs.nil?
	    str = ''
	    @attrs.each { | key, val |
		str << " #{key}=\"#{val.to_s}\""
	    }
	    return str
	end

    end

    class Tag < NamedAttributes

	attr_reader :isTagEnd

	def initialize(name, attrs, isTagEnd=false, source=nil)
	    super(name, attrs, source)
	    @isTagEnd = isTagEnd
	end

	def ==(anObj)
	    return super(anObj) &&
		@isTagEnd == anObj.isTagEnd
	end

	def isTagStart
	    return !@isTagEnd
	end
	alias_method :tagStart?, :isTagStart
	alias_method :tagEnd?, :isTagEnd

	# Write XML to io. Use the "<<" method, not print or puts, because
	# io might be a String or Array and not an IO object.
	def writeXMLTo(io, beforeChildren=true)
	    if beforeChildren
		io << "<#{name}" << attributesToXML() << ">"
	    else
		io << "</#{name}>"
	    end
	end

	# Prints tag. If it's start of tag, prints unencoded attributes.
	def to_s
	    return isTagEnd ? "</#{name}>" :
		"<#{name}" << attributesToString() << ">"
	end
    end

    class Text < Entity

	attr_reader :text

	def initialize(text, source=nil)
	    super(source)
	    @text = text
	end

	# We ignore the source attribute because during parsing entity
	# reference substitution may cause us to lose the ability to know
	# what the original XML source was.
	def ==(anObj)
	    return anObj.instance_of?(self.class) &&
  		@text == anObj.text
	end

	# Returns text with all entities replaced.
	def to_s
	    return @text
	end

	# Write XML to io. Use the "<<" method, not print or puts, because
	# io might be a String or Array and not an IO object.
	def writeXMLTo(io, beforeChildren=true)
	    if beforeChildren
		io << @source if @source
		io << NQXML.encode(@text) if !@source
	    end
	end
    end

    class Comment < Entity

	attr_reader :text

	def initialize(source, internalEntities = nil)
	    super(source)

	    @source =~ /<!--(.*)-->/m
	    @text = $1.strip()
	end

	def ==(anObj)
	    return super(anObj) &&
		@text == anObj.text
	end
    end

    # Used for all processing instructions except '<?xml version="1.0"?>'.
    class ProcessingInstruction < NamedEntity

	attr_reader :text

	def initialize(name, text='', source=nil)
	    super(name, source)
	    @text = text
	end

	# Write XML to io. Use the "<<" method, not print or puts, because
	# this might be a String or Array and not an IO object.
	def writeXMLTo(io, beforeChildren=true)
	    io << "<?#{name} #{text}?>" if beforeChildren
	end
    end

    # Only used for the '<?xml version="1.0"?>' processing instruction.
    class XMLDecl < NamedAttributes
	# Write XML to io. Use the "<<" method, not print or puts, because
	# this might be a String or Array and not an IO object.
	def writeXMLTo(io, beforeChildren=true)
	    if beforeChildren
		io << "<?xml"
		io << " version=\"" << attrs['version'] << '"'
		if attrs['encoding']
		    io << " encoding=\"" << attrs['encoding'] << '"'
		end
		if attrs['standalone']
			io << " standalone=\"" << attrs['standalone'] << '"'
		end
		io << "?>"
	    end
	end
    end

    # ExternalID is the abstract superclass of SystemExternalID and
    # PublicExternalID. These external ids may be found in DOCTYPE and
    # ENTITY tags.
    class ExternalID < Entity
	def initialize(source=nil)
	    super(source)
	end

	def writeXMLTo(io, beforeChildren=true)
	    io << self.to_s if beforeChildren
	end
    end

    # A SYSTEM external id, found in DOCTYPE and ENTITY tags.
    class SystemExternalID < ExternalID
	attr_reader :systemLiteral

	def initialize(systemLiteral, source=nil)
	    super(source)
	    @systemLiteral = systemLiteral
	end

	def ==(anObj)
	    return super(anObj) &&
		@systemLiteral == anObj.systemLiteral
	end

	def to_s
	    return "SYSTEM #{systemLiteral}"
	end
    end

    # A PUBLIC external id, found in DOCTYPE and ENTITY tags.
    class PublicExternalID < ExternalID
	attr_reader :pubidLiteral, :systemLiteral

	def initialize(pubidLiteral, systemLiteral, source=nil)
	    super(source)
	    @pubidLiteral = pubidLiteral
	    @systemLiteral = systemLiteral
	end

	def ==(anObj)
	    return super(anObj) &&
		@pubidLiteral == anObj.pubidLiteral &&
		@systemLiteral == anObj.systemLiteral
	end

	def to_s
	    return "PUBLIC #{pubidLiteral} #{systemLiteral}"
	end
    end

    # Entity tag is the abstract superclass of general and parameter
    # entity tags.
    class EntityTag < NamedEntity

	attr_reader :entityValue, :externalId

	def initialize(name, entityValue, externalId, source=nil)
	    super(name, source)
	    @entityValue = entityValue
	    @externalId = externalId
	end

	def ==(anObj)
	    return super(anObj) &&
		@entityValue == anObj.entityValue &&
		@externalId == anObj.externalId
	end

	# Write XML to io. Use the "<<" method, not print or puts, because
	# this might be a String or Array and not an IO object.
	def writeXMLTo(io, beforeChildren=true)
	    if beforeChildren
		io << @source
	    end
	end
    end

    # A general entity will contain either a
    class GeneralEntityTag < EntityTag

	attr_reader  :nDataDeclName

	def initialize(name, entityValue, externalId, nDataDecl, source=nil)
	    super(name, entityValue, externalId, source)
	    @nDataDeclName = nDataDeclName
	end

	def ==(anObj)
	    return super(anObj) &&
		@nDataDeclName == anObj.nDataDeclName
	end

	# Write XML to io. Use the "<<" method, not print or puts, because
	# this might be a String or Array and not an IO object.
	def writeXMLTo(io, beforeChildren=true)
	    if beforeChildren
		io << "<!ENTITY #{name} "
		if entityValue
		    io << "\"#{entityValue}\""
		else
		    io << ' ' << externalId << ' NDATA ' << nDataDeclName
		end
		io << ">"
	    end
	end

    end

    class ParameterEntityTag < EntityTag

	def initialize(name, entityValue, externalId, source=nil)
	    super(name, entityValue, externalId, source)
	end

	# Write XML to io. Use the "<<" method, not print or puts, because
	# this might be a String or Array and not an IO object.
	def writeXMLTo(io, beforeChildren=true)
	    if beforeChildren
		io << "<!ENTITY #{name} "
		if entityValue
		    io << "\"#{entityValue}\""
		else
		    io << ' ' << externalId
		end
		io << ">"
	    end
	end

    end

    # For now, behaves exactly like entity tag. Will change later.
    class Element < NamedEntity
	attr_reader :argString
	def initialize(name, argString, source=nil)
	    super(name, source)
	    @argString = argString
	end
	def ==(anObj)
	    return super(anObj) &&
		@argString == anObj.argString
	end
    end

    # For now, behaves exactly like entity tag. Will change later.
    class Attlist < NamedEntity
	attr_reader :argString
	def initialize(name, argString, source=nil)
	    super(name, source)
	    @argString = argString
	end
	def ==(anObj)
	    return super(anObj) &&
		@argString == anObj.argString
	end
    end

    # For now, behaves exactly like entity tag. Will change later.
    class Notation < NamedEntity
	attr_reader :argString
	def initialize(name, argString, source=nil)
	    super(name, source)
	    @argString = argString
	end
	def ==(anObj)
	    return super(anObj) &&
		@argString == anObj.argString
	end
    end

    class Doctype < NamedEntity

	attr_reader :externalId, :entities

	def initialize(name, externalId, entities, source=nil)
	    super(name, source)
	    @externalId = externalId
	    @entities = entities
	end

	def ==(anObj)
	    return super(anObj) &&
		@externalId == anObj.externalId &&
		@entities == anObj.entities
	end

	# Write XML to io. Use the "<<" method, not print or puts, because
	# this might be a String or Array and not an IO object.
	def writeXMLTo(io, beforeChildren=true)
	    if beforeChildren
		io << "<!DOCTYPE #{@name}"
		io << ' ' << @externalId.to_s if @externalId
		if @entities && !@entities.empty?
		    io << ' ['
		    @entities.each { | e |
			io << "\n"
			e.writeXMLTo(io, beforeChildren)
		    }
		    io << ']>'
		else
		    io << '>'
		end
	    end
	end
    end

end
