# $Id: dispatcher.rb,v 1.1 2004/04/21 21:33:15 tirsen Exp $
# $Author: tirsen $
#
# NQXML::Dispatcher -- simple callback service for NQXML
#		      streaming parser
#
# David Alan Black (dblack@candle.superlink.net)
# July 2001
#
# Documentation at end.
#
# Thanks to Jim Menard and Dave Thomas.
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#

require "nqxml/streamingparser"

module NQXML

  class Entity
    def event_key
    end
  end

  class Tag
    def event_key
      if tagStart?
        :start_element
      else
        :end_element
      end
    end
  end

  class Text
    def event_key
      :text
    end
  end

  class Comment
    def event_key
      :comment
    end
  end

  class Dispatcher < StreamingParser

    DEBUG = false
    @@events = %w{start_element end_element text comment}

    def initialize(*args)
      @jump_tables = {}
      super
    end

    def handle(event,*nest,&block)
      unless block
	raise ArgumentError, "Missing code block"
      end
      context = nest.flatten.map do |n| n = n.to_s end
      @jump_tables[event] ||= {}
      @jump_tables[event][context] = block
    end

    def dispatch(entity,context,jump_table)
      cdup = context.dup
      jump_table ||= {}
      until jump_table[cdup] || cdup.empty?
	cdup.shift
      end
      if jump_table[cdup]
	jump_table[cdup].call(entity)
      else
	wild = star_match(context,jump_table)
	if wild
	  wild.call(entity)
	end
      end
    end

    def star_match(context,registry)
      cstar = context.dup
      matched = false
      until matched || cstar.empty?
	cstar[-1] = "*"
	matched = registry[cstar]
	cstar.shift unless matched
      end
      matched
    end

    def start
      context = []
      each do |e|
	k = e.event_key
	if k
	  if e.respond_to? :tagStart?
	    context.push(e.name) if e.tagStart?
	  end

	  dispatch(e,context,@jump_tables[k])

	  if e.respond_to? :tagEnd?
	    context.pop if e.tagEnd?
	  end
	end
      end
    end

  end
end

=begin

This class allows you to register handlers (callbacks) for
entering and/or exiting a given context.

Usage:

1. CREATE A NEW DISPATCHER:

      nd = NQXML::Dispatcher.new(args)

      # args are same as for NQXML::StreamingParser


2. REGISTER HANDLERS FOR VARIOUS EVENTS

The streaming parser provides a stream of four types of entity: (1)
element start-tags, (2) element end-tags, (3) text segments, and (4)
comments.  You can register handlers for any or all of these.  You do
this by writing a code block which you want executed every time one of
the four types is encountered in the stream in a certain context.

"Context," in this context, means nesting of elements -- for instance,
(book(chapter(paragraph))).  See the examples, below, for more on
this.

The handler will return the entity that triggered it back to the
block, so the block should be prepared to grab it.  (See documentation
for NQXML::StreamingParser and other components of NQXML for more
information on this.)

Examples:

  NOTE: When you register a handler, you specify an event, a context,
  and an action (block).  The event must be a symbol.  The context may
  be a list of strings, a list of symbols, an array of strings, or an
  array of symbols.

  A. Register a handler for starting an element.  Arguments are: context
  and a block, where context is an array of element names, in order of
  desired nesting, and block is a block.

     # For every new <chapter> element inside a <book> element:
     nd.handle(:start_element, [ :book, :chapter ]) { |e| puts "Chapter startin\
g" }


  B. Register a handler for dealing with text inside an element:

     # Print book chapter titles in bold (LaTex):
     nd.handle(:text, "book", "chapter", "title") { |e|
       puts "\\textbf{#{e.text}}"
     }


  C. Register a handler for end of an element:

     nd.handle(:end_element, %w{book chapter}) { |e|
       puts "Chapter over"
     }


  D. Register a handler for all XML comments:

     # Note that this can be done one of two ways:
       nd.handle(:comment) { |c| puts "Comment: #{c} }
       nd.handle(:comment, "*") { |c| puts "Comment: #{c} }


3. BEGIN THE PARSE

     nd.start


4. WILDCARDS

NQXML::Dispatcher offers a lightweight wildcard facility.  The single
wildcard character "*" may be used as the last item in specifying
a context.  This is a "one-or-more" wildcard.  See below for further
explanation of its use.


5. How NQXML::Dispatcher matches contexts

In looking for a match between the current event and context with its
list of registered event/context handlers, the Dispatcher looks first
for an exact match.  Then it starts peeling off context from the left
(e.g., if it doesn't find a match for book/chapter/paragraph, it looks
next for chapter/paragraph).  If no exact match can be found that way,
it reverts to the full context specification and starts replacing
right-most items with "*".  It works leftward through the items,
looking for a match.

Some examples:

   If you define callbacks for these contexts:

     1. [book chapter paragraph bold]
     2. [paragraph bold]
     3. [book chapter *]
     4. [chapter *]

   then the following matches will hold:

     [book intro paragraph bold]    matches 2
     [bold]			    no match
     [book chapter paragraph]       matches 3
     [chapter paragraph]	    matches 4
     [book appendix chapter figure] matches 4
=end
