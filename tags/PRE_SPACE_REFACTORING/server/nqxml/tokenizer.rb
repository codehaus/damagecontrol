#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#

require 'nqxml/error'
require 'nqxml/entities'
require 'nqxml/utils'

module NQXML

    class Input
	attr_accessor :pos
	attr_reader :string, :length, :replaceRefs
	def initialize(str, replaceRefs)
	    @string = str
	    @replaceRefs = replaceRefs
	    @pos = 0
	    @length = @string.length
	end
	def eof?
	    return @pos >= @length
	end
    end

    class Tokenizer

	# Don't need \xd because we either strip them or turn them into \xa
	# on the way in.
	NOT_SPACES_REGEX = /[^\x20\x9\xa]/m
	# Unnecessary backslashes, yes, but I was getting funky errors
	PUBLIC_ID_LITERAL_REGEX =
	    /\A[-a-zA-Z0-9\'\{\}\+\,\.\/\:\=\?\;!\*\#\@\$\_\%\x20\xa]+\z/
	NAME_REGEX = /^([a-zA-Z_:\xc0-\xd6\xd8-\xf6\xf8-\xff][-a-zA-Z0-9_:\.\xc0-\xd6\xd8-\xf6\xf8-\xff\xb7]*)/
	ENCODING_NAME_REGEX = /\A[A-Za-z][-A-Za-z0-9\._]+\z/
	BRACKET_OR_AMP_REGEX = /[<&]/

	def initialize(stringOrReadable)
	    xml = nil
	    @inputStack = Array.new()

	    if stringOrReadable.kind_of?(String)
		xml = stringOrReadable
	    elsif stringOrReadable.respond_to?(:read)
		xml = stringOrReadable.read()
	    else
		str = "illegal argument: #{stringOrReadable} must be a" +
		    "String or have a 'read' method"
		raise ParserError.new(str, self)
	    end

	    # All line breaks normalized on input to #xA.
  	    xml.gsub!("\r\n", "\n")
  	    xml.gsub!("\r", "\n")

	    @inputStack.push(@currInput = Input.new(xml, true))

	    @generatedEndTag = nil
	    @internalEntities = Hash.new()
	    @paramEntities = Hash.new()
	end

	def eof?
#  	    return @generatedEndTag.nil? && @inputStack[0].eof?
 	    return @generatedEndTag.nil? &&
		@inputStack[0].pos >= @inputStack[0].length
	end
	alias_method :atEnd, :eof?
	alias_method :eof, :eof?

	# Returns the line number within the XML.
	def line
	    return -1 if @inputStack.empty? # only if initialize() arg is bogus

	    input = @inputStack[0] # not @inputStack.last
	    str = input.string[0 .. input.pos]
	    return str.count("\n") + 1
	end

	# Returns the column number within the current line of XML.
	def column
	    return -1 if @inputStack.empty? # only if initialize() arg is bogus

	    input = @inputStack[0] # not @inputStack.last
	    currLineStart = input.string.rindex("\n", input.pos)
	    return input.pos + 1 if currLineStart.nil?
	    return input.pos - currLineStart + 1
	end

	# Replace general entity refs, but not predefined and character refs.
	# Returns the replacement string if any substitutions were performed.
	# If not, returns nil to signal end of recursive replacement.
	def replaceOnlyEntityRefs(str)
	    return nil if str.nil?
	    copy = str.dup
	    replacement = ''
	    while copy =~ /&([^&;]*);/mn
		replacement << $`
		ref = $&
		refName = $1
		copy = $'
		if refName =~ /\A(#[0-9]*|#x[0-9A-Fa-f]|amp|quot|apos|gt|lt)\z/n
		    replacement << ref
		else
		    val = @internalEntities[refName]
		    if val.nil?
			str = "entity reference '#{ref}' is undefined"
			raise ParserError.new(str, self)
		    end
		    val = replaceAllRefsButParams(val)
		    replacement << val
		end
	    end
	    replacement << copy
	    return replacement
	end

	# Replace character, predefined, and general entity refs.
	def replaceAllRefsButParams(str)
	    return nil if str.nil?
	    copy = NQXML.replaceCharacterRefs(str)
	    copy = NQXML.replacePredefinedEntityRefs(copy)
	    return replaceOnlyEntityRefs(copy)
	end

	# Parse character refs and parameter refs at the same time,
	# but not general entity refs.
	def replaceParamRefs(str)
	    return nil if str.nil?
	    copy = str.dup
	    replacement = ''
	    while copy =~ /%([^%;]*);/mn
		replacement << $`
		ref = $&
		refName = $1
		copy = $'
		val = @paramEntities[refName]
		if val.nil?
		    str = "entity reference '#{ref}' is undefined"
		    raise ParserError.new(str, self)
		end
		val = replaceParamRefs(val)
		replacement << val
	    end
	    replacement << copy
	    return replacement
	end

	# Return the currently-used input object. If the input on the top
	# of the stack is empty, pop it off the stack and return the next one.
	#
	# Now inlined everywhere this used to be called.
#  	def input
#  	    while @currInput.pos >= @currInput.length
#  		@inputStack.pop()
#  		@currInput = @inputStack.last
#  	    end
#  	    return @currInput
#  	end

	# Returns true if str matches the beginning of the current
	# position in input stream.
	def peekMatches?(str)
  	    while @currInput.pos >= @currInput.length
		@inputStack.pop()
		@currInput = @inputStack.last
	    end

	    return @currInput.string[@currInput.pos, str.length] == str
	end

	def peekChar()
	    while @currInput.pos >= @currInput.length
		@inputStack.pop()
		@currInput = @inputStack.last
	    end

	    return @currInput.string[@currInput.pos, 1]
	end

	def nextChar(n = 1)
	    while @currInput.pos >= @currInput.length
		@inputStack.pop()
		@currInput = @inputStack.last
	    end

	    str = @currInput.string[@currInput.pos, n]
	    @currInput.pos += n
	    return str
	end
	alias_method :nextChars, :nextChar

	def skipChar(n = 1)
	    while @currInput.pos >= @currInput.length
		@inputStack.pop()
		@currInput = @inputStack.last
	    end

	    @currInput.pos += n
	end
	alias_method :skipChars, :skipChar

	def skipSpaces
	    while @currInput.pos >= @currInput.length
		@inputStack.pop()
		@currInput = @inputStack.last
	    end

	    endOfSpaces = @currInput.string.index(NOT_SPACES_REGEX,
						  @currInput.pos)
	    if endOfSpaces.nil?
		# There's nothing but whitespace from here until end of the
		# current input stream. Pop this input and continue searching.
		@currInput.pos = @currInput.length

		while @currInput.pos >= @currInput.length
		    @inputStack.pop()
		    @currInput = @inputStack.last
		end

		skipSpaces() if @currInput
	    else
		@currInput.pos = endOfSpaces
	    end
	end

	# Returns text up to but not including specified string or regexp.
	# Positions text cursor after the text found.
	def textUpTo(str, strIsRegex, errorIfNotFound)
	    while @currInput.pos >= @currInput.length
		@inputStack.pop()
		@currInput = @inputStack.last
	    end

	    if strIsRegex
		textEnd = (str =~ @currInput.string[@currInput.pos .. -1])
		textEnd += @currInput.pos if textEnd
	    else
		textEnd = @currInput.string.index(str, @currInput.pos)
	    end

	    # Throw error here if no char found and if errorIfNotFound is
	    # true.
	    if textEnd.nil?
		if errorIfNotFound
		    raise ParserError.new("unexpected EOF: missing #{str}",
					  self)
		end
		textEnd = @currInput.length
	    end

	    range = (@currInput.pos ... textEnd)
	    text = @currInput.string[range]
	    skipChars(text.length)
	    return text
	end

	# Returns the next legal XML name. Will raise an exception if the
	# next available character is not legal.
	def nextName
	    while @currInput.pos >= @currInput.length
		@inputStack.pop()
		@currInput = @inputStack.last
	    end

	    @currInput.string[@currInput.pos .. -1] =~ NAME_REGEX
	    name = $1
	    if name.nil?
		str = "expected name but saw illegal non-name character"
		raise ParserError.new(str, self)
	    end
	    skipChars(name.length)
	    return name
	end

	def nextQuotedLiteral(tagName)
	    quote = peekChar()
	    if quote != '"' && quote != "'"
		str = "quoted literal not quoted in tag #{tagName}"
		raise ParserError.new(str, self)
	    end
	    skipChar()		# eat quote

	    text = textUpTo(quote, false, true)

	    skipChar()		# eat quote
	    return text
	end

	# Returns a PUBLIC id literal, which is different from a "simple"
	# quoted literal.
	def nextPublicIdLiteral(tagName)
	    quote = peekChar()
	    if quote != '"' && quote != "'"
		str = "quoted literal not quoted in #{tagName} PUBLIC id"
		raise ParserError.new(str, self)
	    end
	    skipChar()		# eat quote

	    text = textUpTo(quote, false, true)
	    if !(text =~ PUBLIC_ID_LITERAL_REGEX)
		str = "#{tagName} PUBLIC public id literal contains illegal" +
		 ' character(s)'
		 raise ParserError.new(str, self)
	     end
	    skipChar()		# eat quote

# FIX - we are returning literal text, but should do something
# intelligent.

	    return quote + text + quote
	end

	# Normalize the attribute value using the rules in section 3.3.3 of
	# the XML spec, "Attribute-Value Normalization".
	def normalizeAttributeValue(str)
	    return nil if str.nil?
	    val = str.dup
	    result = ''
	    until val.empty?
		pos = val =~ /[&\s<]/m
		if pos.nil?
		    result << val
		    return result
		end
		result << $`
		val = val[pos .. -1]
		if val =~ /\A&#x([0-9a-f]*);/ni
		    result << $1.hex.chr
		    val = $'
		elsif val =~ /\A&#([0-9]*);/n
		    result << $1.to_i.chr
		    val = $'
		elsif val =~ /\A&([^&;]*);/n
		    ref = $1
		    case ref
		    when 'amp'; result << '&'
		    when 'lt'; result << '<'
		    when 'gt'; result << '>'
		    when 'quot'; result << '"'
		    when 'apos'; result << '\''
		    else
			replacement = @internalEntities[ref]
			if replacement.nil?
			    str = "entity reference '#{ref}' is undefined"
			    raise ParserError.new(str, self)
			end
			if !replacement.index('<').nil?
			    str = "attribute values may not contain '<'"
			    raise ParserError.new(str, self)
			end
			result << normalizeAttributeValue(replacement)
		    end
		    val = $'
		elsif val =~ /\A\s+/m
		    result << ' '
		    val = $'
		elsif val[0] == ?<
			str = "attribute values may not contain '<'"
		    raise ParserError.new(str, self)
		end
	    end
	    return result
	end

	# Returns hash of attributes. If no attributes, returns empty hash.
	# If error, raises an exception.
	def nextTagAttributes(typeName, name)
	    attrs = Hash.new()
	    skipSpaces()
	    c = peekChar()
	    while !c.nil? && c =~ /[a-zA-Z_:]/ # next legal attrib name char
		key = nextName()
		skipSpaces()
		if peekMatches?('=')
		    skipChar()
		    skipSpaces()
		    val = nextQuotedLiteral(name)
		    val = normalizeAttributeValue(val)
		else
		    val = ''
		end

		# Well-formedness constraint: attribute names may appear
		# only once.
		if !attrs[key].nil?
		    str = "malformed #{typeName} '#{name}': attribute name" +
			" '#{key}' appears more than once"
		    raise ParserError.new(str, self)
		end

		attrs[key] = val

		skipSpaces()
		c = peekChar()
	    end
	    return attrs
	end

	def restOfXMLDecl(name, input, sourceStartPos)
	    # Read attributes, if any.
	    attrs = nextTagAttributes('xml decl', name)

	    # Make sure we close with '?>'
	    skipSpaces()
	    if !peekMatches?('?>')
		str = "malformed processing instruction '#{name}':" +
		    " missing '?>' after attributes"
		raise ParserError.new(str, self)
	    end
	    skipChars(2)	# eat '?>'

	    if attrs['encoding'] && attrs['encoding'] !~ ENCODING_NAME_REGEX
		str = "xml encoding name \"#{attrs['encoding']}\" contains" +
		    " illegal characters"
		raise ParserError.new(str, self)
	    end
	    if attrs['standalone'] && !(attrs['standalone'] == 'yes' ||
					attrs['standalone'] == 'no')
		str = "xml standalone attribute \"#{attrs['standalone']}\"" +
		    " illegal; must be \"yes\" or \"no\""
		raise ParserError.new(str, self)
	    end

	    source = input.string[sourceStartPos ... input.pos]
	    return XMLDecl.new(name, attrs, source)
	end

	def restOfProcessingInstruction(name, input, sourceStartPos)
	    text = textUpTo('?>', false, true) # Read remaining text
	    skipChars(2)	# eat '?>'

	    source = input.string[sourceStartPos ... input.pos]
	    return ProcessingInstruction.new(name, text, source)
	end

	def nextProcessingInstruction
	    while @currInput.pos >= @currInput.length
		@inputStack.pop()
		@currInput = @inputStack.last
	    end

	    sourceStartPos = @currInput.pos - 2

	    # Get name
	    # do not skip spaces; they are not allowed before the name.
	    # skipSpaces()
	    name = nextName()
	    skipSpaces()

	    if name.downcase == 'xml'
		return restOfXMLDecl(name, @currInput, sourceStartPos)
	    else
		return restOfProcessingInstruction(name, @currInput,
						   sourceStartPos)
	    end
	end

	# Handle declsep (parameter entity reference) inside DOCTYPE.
	# Unlike most next* methods, we don't return an entity. Instead we
	# replace the declsep (parameter entity reference) and create
	# a new input stream containing the replacement text.
	def nextDeclSep
	    while @currInput.pos >= @currInput.length
		@inputStack.pop()
		@currInput = @inputStack.last
	    end

	    startPos = @currInput.pos - 1
	    name = nextName()
	    if !peekMatches?(';')
		str = "illegal parameter entity reference '%#{name}' is" +
		    " missing trailing semicolon"
		raise ParserError.new(str, self)
	    end
	    skipChar()		# eat ';'

	    # Get replacement text and raise an error if it is not defined.
	    # Per the XML spec, surround replacement with single spaces.
	    if @paramEntities[name].nil?
		str = "undefined parameter entity '%#{name};' in DOCTYPE tag"
		raise ParserError.new(str, self)
	    end
	    replacement = ' ' + @paramEntities[name] + ' '

	    # Create a new input stream.
	    @inputStack.push(@currInput = Input.new(replacement, true))
	end

	def nextComment
	    text = textUpTo('-->', false, true)
	    while text[-1] == '-' # "--->" is not a legal comment ending
		$stderr.puts "warning: illegal comment end string '--->'" +
		    " seen and ignored"
		skipChars(3)	# eat '-->'
		text << textUpTo('-->', false, true)
	    end
	    skipChars(3)	# eat '-->'
	    return Comment.new("<!--#{text}-->", @internalEntities)
	end

	def nextCdata
	    skipChars(7)	# eat '[CDATA['
	    text = textUpTo(']]>', false, true)
	    skipChars(3)	# eat ']]>'
	    return Text.new(text, "<![CDATA[#{text}]]>")
	end

	# Return next PUBLIC or SYSTEM external id. Returns nil if the
	# next word is not either 'PUBLIC' or 'SYSTEM'.
	def nextExternalId(tagName)
	    externalId = nil
	    idSourceStartPos = @currInput.pos
	    if peekMatches?('PUBLIC')
		skipChars(6)
		skipSpaces()
		pubid = nextPublicIdLiteral(tagName)
		skipSpaces()
		c = peekChar()
		if c == '>' || c == '['
		    str = "#{tagName} tag's PUBLIC external id requires two" +
			" arguments; only one seen"
		    raise ParserError.new(str, self)
		end

		# c is quote char (we need to hang on to it because we
		# loose it in nextQuotedLiteral()). If the next char isn't
		# a quote char, then nextQuotedLiteral() will do the
		# complaining for us.
		system = c + nextQuotedLiteral("#{tagName} (PUBLIC)") + c
		source = @currInput.string[idSourceStartPos ... @currInput.pos]
		externalId = PublicExternalID.new(pubid, system, source)
	    elsif peekMatches?('SYSTEM')
		skipChars(6)
		skipSpaces()
		c = peekChar()	# Grab quote char
		system = c + nextQuotedLiteral("#{tagName} (SYSTEM)") + c
		source = @currInput.string[idSourceStartPos ... @currInput.pos]
		externalId = SystemExternalID.new(system, source)

		# A bit of extra error checking
		skipSpaces()
		if peekChar() == '"'
		    str = "#{tagName} tag's SYSTEM external id only has one" +
			" argument; two seen"
		    raise ParserError.new(str, self)
		end
	    end
	    return externalId
	end

	def nextEntityTag
	    while @currInput.pos >= @currInput.length
		@inputStack.pop()
		@currInput = @inputStack.last
	    end

	    sourceStartPos = @currInput.pos
	    skipChars(8)	# eat '<!ENTITY'

	    skipSpaces()

	    errorStrExtra = ''
	    type = :GENERAL_ENTITY
	    if peekMatches?('%') # it's a parameter entity definition
		skipChar(1)	# eat '%'
		skipSpaces()
		type = :PARAMETER_ENTITY
		errorStrExtra = '% '
	    end

	    name = nextName()
	    skipSpaces()

	    # Page 39 ofspec: if GE def, EntityValue | (ExternalID
	    # NDataDecl) if PE def, EntityValue | ExternalID

	    entityValue = nil
	    externalId = nil
	    ndataName = nil
	    if peekMatches?('SYSTEM') || peekMatches?('PUBLIC')
		externalId = nextExternalId('ENTITY')
		skipSpaces()
		if type == :GENERAL_ENTITY
		    # NDATA
		    if peekMatches?('NDATA')
			skipChars(5)
			skipSpaces()
			ndataName = nextName()
		    end
		end
	    else		# EntityValue
		# Parse character refs and parameter refs at the same time,
		# but not general entity refs.
		entityValue = replaceParamRefs(nextQuotedLiteral(name))
		entityValue = NQXML.replaceCharacterRefs(entityValue)
	    end
	    skipSpaces()

	    # Add to list of parameter or internal entities for future
	    # substitution. Warn the user if it has already been defined.
# FIX: what is hash val when we've seen an external id (and possibly an NDATA)
	    entityHash = (type == :PARAMETER_ENTITY ? @paramEntities :
			  @internalEntities)
	    if entityHash[name]
		$stderr.puts "warning: ENTITY #{errorStrExtra}'#{name}'" +
		    " already defined; first definition will be used"
	    else
		entityHash[name] = entityValue
	    end

	    if !peekMatches?('>')
		str = "missing '>' after ENTITY #{errorStrExtra}" +
		    "'#{name}' value"
		raise ParserError.new(str, self)
	    end
	    skipChar()		# eat '>'

	    src = @currInput.string[sourceStartPos ... @currInput.pos]
	    if type == :PARAMETER_ENTITY
		return ParameterEntityTag.new(name, entityValue, externalId,
					      src)
	    else
		return GeneralEntityTag.new(name, entityValue, externalId,
					    ndataName, src)
	    end
	end

	def nextElementDecl
	    while @currInput.pos >= @currInput.length
		@inputStack.pop()
		@currInput = @inputStack.last
	    end

	    sourceStartPos = @currInput.pos
	    skipChars(9)	# eat '<!ELEMENT'

	    skipSpaces()
	    name = nextName()
	    skipSpaces()

	    # FIX THIS; we are treating args as a blob of text.
	    args = textUpTo('>', false, true)
	    skipChar()		# eat '>'

	    return Element.new(name, args,
			       @currInput.string[sourceStartPos ... @currInput.pos])
	end

	def nextAttributeList
	    while @currInput.pos >= @currInput.length
		@inputStack.pop()
		@currInput = @inputStack.last
	    end

	    sourceStartPos = @currInput.pos
	    skipChars(9)	# eat '<!ATTLIST'

	    skipSpaces()
	    name = nextName()
	    skipSpaces()

	    # FIX THIS; we are treating args as a blob of text.
	    args = textUpTo('>', false, true)
	    skipChar()		# eat '>'

	    return Attlist.new(name, args,
			       @currInput.string[sourceStartPos ... @currInput.pos])
	end

	def nextNotation
	    while @currInput.pos >= @currInput.length
		@inputStack.pop()
		@currInput = @inputStack.last
	    end

	    sourceStartPos = @currInput.pos
	    skipChars(10)	# eat '<!NOTATION'

	    skipSpaces()
	    name = nextName()
	    skipSpaces()

	    # FIX THIS; we are treating args as a blob of text.
	    args = textUpTo('>', false, true)
	    skipChar()		# eat '>'

	    return Notation.new(name, args,
				@currInput.string[sourceStartPos ... @currInput.pos])
	end

	# '<!DOCTYPE' (name) (external-id)?
	# 	( '[' (markupdecl | declsep)* ']' )? '>'
	def nextDoctype
	    while @currInput.pos >= @currInput.length
		@inputStack.pop()
		@currInput = @inputStack.last
	    end

	    sourceStartPos = @currInput.pos - 2
	    skipChars(7)	# eat 'DOCTYPE'

	    # Name
	    skipSpaces()
	    name = nextName()

	    # External id
	    skipSpaces()
	    externalId = nextExternalId('DOCTYPE') # May return nil

	    # Markupdecl and declsep entities, if any
	    skipSpaces()
	    entities = nil
	    if peekMatches?('[')
		# markupdecl and declsep entities
		entities = Array.new()
		skipChar()	# eat '['
		skipSpaces()
		while !peekMatches?(']')
		    if peekMatches?('<!ENTITY')
			entities << nextEntityTag()
		    elsif peekMatches?('<!ELEMENT')
			entities << nextElementDecl()
		    elsif peekMatches?('<!ATTLIST')
			entities << nextAttributeList()
		    elsif peekMatches?('<!NOTATION')
			entities << nextNotation()
		    elsif peekMatches?('<?')
			skipChars(2)
			entities << nextProcessingInstruction()
		    elsif peekMatches?('<!--')
			skipChars(4)
			entities << nextComment()
		    elsif peekMatches?('%')
			# DeclSep (PEReference)
			skipChar()
			# We won't get back an entity. Instead, we will
			# re-parse the new input stream created by
			# nextDeclSep().
			nextDeclSep()
		    else
			str = 'unknown or illegal tag inside DOCTYPE tag;' +
			    " first 8 chars = '#{nextChars(8)}'"
			raise ParserError.new(str, self)
		    end
		    skipSpaces()
		end
		skipChar()	# eat ']'
	    end

	    if !peekMatches?('>')
		raise ParserError.new("DOCTYPE tag missing '>'", self)
	    end
	    skipChar()		# eat '>'

	    return Doctype.new(name, externalId, entities,
			       @currInput.string[sourceStartPos ... @currInput.pos])
			       
	end

	def nextBangTag
	    if peekMatches?('--')
		skipChars(2)
		return nextComment()
	    elsif peekMatches?('[CDATA[')
		return nextCdata()
	    elsif peekMatches?('DOCTYPE')
		nextDoctype()
	    else
		text = textUpTo('>', false, true)
		raise ParserError.new("unknown or unexpected tag <!#{text}>",
				      self)
	    end
	end

	def nextTag
	    while @currInput.pos >= @currInput.length
		@inputStack.pop()
		@currInput = @inputStack.last
	    end

	    sourceStartPos = @currInput.pos - 1

	    # Determine if negated by starting slash
	    isTagEnd = peekMatches?('/')
	    skipChar() if isTagEnd

	    # Get name
	    skipSpaces()
	    name = nextName()

	    # Read attributes
	    attrs = isTagEnd ? nil :
		nextTagAttributes('tag', name)

	    # Check for slash at end of tag
	    skipSpaces()
	    c = peekChar()
	    makeNegatedCopy = (c == '/')
	    if makeNegatedCopy
		if isTagEnd
		    str = "malformed tag '#{name}': slash appears at both" +
			" beginning and end of tag"
		    raise ParserError.new(str, self)
		end
		skipChar()	# eat '/'
		c = peekChar()
	    end

	    if c != '>'
		str = "malformed tag '#{name}': missing '>' after attributes"
		raise ParserError.new(str, self)
	    end
	    skipChar()		# eat '>'

	    source = @currInput.string[sourceStartPos ... @currInput.pos]
	    if makeNegatedCopy
		# Create tag for next token and get rid of trailing slash
		# in source text.
		@generatedEndTag = Tag.new(name, nil, true, source)
	    end
	    return Tag.new(name, attrs, isTagEnd, source)
	end

	def nextBracketToken
	    skipChar()		# eat '<'
	    c = peekChar()
	    case c
	    when '?'
		skipChar()	# eat '?'
		return nextProcessingInstruction()
	    when '!'
		skipChar()	# eat '!'
		return nextBangTag()
	    else
		return nextTag()
	    end
	end

	def nextText
	    text = ''
	    while true
		text << textUpTo(BRACKET_OR_AMP_REGEX, true, false)
		# We are done if this is the end of this input stream or
		# if the next char is a '<'. NOTE: the check for eof must
		# come first because peekChar() will go beyond eof to the
		# next (popped) input stream.
		if eof?() || peekChar() == '<'
		    return text.empty? ? nil : Text.new(text)
		end

		if peekChar() == '&'
		    ref = textUpTo(';', false, true) # '&...'
		    ref << nextChar() # ';'
		    ref = NQXML.replaceCharacterRefs(ref)
		    ref = NQXML.replacePredefinedEntityRefs(ref)

		    if ref[0] == ?& && ref.length > 1 &&
			    @inputStack.last.replaceRefs
			# We are looking at an entity reference, and this
			# input wants to replace those.
			replacement = @internalEntities[ref[1..-2]]

			if replacement.nil?
			    str = "entity reference '#{ref}' is undefined"
			    raise ParserError.new(str, self)
			end

			# Before we create a new input object so we can
			# recursively parse the replacement text, let's
			# slurp up as much "simple" text as we can.
			replacement =~ /\A[^<&]*/
			text << $&
			replacement = $'
			if !replacement.empty?
			    @currInput = Input.new(replacement, false)
			    @inputStack.push(@currInput)
			    moreText = nextText()
			    text << moreText.text if moreText
			end
		    else	# append ref to text and move ion
			text << ref
		    end
		end		
	    end
	end

	# Used by each().
	def nextEntity
	    entity = nil
	    if @generatedEndTag
		entity = @generatedEndTag
		@generatedEndTag = nil
	    elsif peekMatches?('<')
		entity = nextBracketToken()
	    else
		entity = nextText()
		# nextText() returns nil when a substitution caused a tag
		# to be introduced into the text.
		entity = nextEntity() if entity.nil?
	    end
	    return entity
	end

	# The main token generator
	def each
	    while !eof()
		yield nextEntity()
	    end
	end

    end				# end of class NQXML::Tokenizer

end				# end of module NQXML
