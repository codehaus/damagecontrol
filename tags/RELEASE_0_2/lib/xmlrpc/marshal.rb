#
# Marshalling of XML-RPC methodCall and methodResponse
# 
# Copyright (C) 2001, 2002 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: marshal.rb,v 1.1 2004/04/21 21:33:17 tirsen Exp $
#

require "xmlrpc/parser"
require "xmlrpc/create"
require "xmlrpc/config"
require "xmlrpc/utils"

module XMLRPC

  class Marshal
    include ParserWriterChooseMixin

    # class methods -------------------------------
   
    class << self

      def dump_call( methodName, *params )
        new.dump_call( methodName, *params )
      end

      def dump_response( param )
        new.dump_response( param )
      end

      def load_call( stringOrReadable )
        new.load_call( stringOrReadable )
      end

      def load_response( stringOrReadable )
        new.load_response( stringOrReadable )
      end

      alias dump dump_response
      alias load load_response

    end # class self

    # instance methods ----------------------------

    def initialize( parser = nil, writer = nil )
      set_parser( parser )
      set_writer( writer )
    end

    def dump_call( methodName, *params )
      create.methodCall( methodName, *params )
    end

    def dump_response( param ) 
      create.methodResponse( ! param.kind_of?( XMLRPC::FaultException ) , param )
    end

    ##
    # returns [ methodname, params ]
    #
    def load_call( stringOrReadable )
      parser.parseMethodCall( stringOrReadable )
    end

    ##
    # returns paramOrFault
    #
    def load_response( stringOrReadable )
      parser.parseMethodResponse( stringOrReadable )[1]
    end

  end # class Marshal

end

