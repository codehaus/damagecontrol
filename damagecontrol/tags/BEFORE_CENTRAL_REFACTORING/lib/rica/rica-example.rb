#!/usr/bin/env ruby
#
# rica-example.rb
#   -- Rica Example
#   NISHI Takao <zophos@koka-in.org>
#
# $Id$
#
require 'rica'

class BotExample<Rica::MessageProcessor
    def initialize
	super()
	@c=nil
    end

    #
    #  print all messages to console
    #
    def default_action(msg)
	print msg.origin,"\n"
    end

    #
    # auto join
    #
    def on_recv_rpl_motd(msg)
	if(@c.nil?)
	    cmnd_join(msg.server,'#RicaTest')
	end
    end

    #
    # respond to join
    #
    def on_recv_cmnd_join(msg)
	if(msg.isSelfMessage?)
	    @c=msg.to
	    cmnd_notice(msg.server,msg.to,"Hello, "+msg.to)
	else
	    cmnd_notice(msg.server,msg.to,"Hello, "+msg.fromNick)
	end
    end

    #
    # respond to privmsg
    #
    def on_recv_cmnd_privmsg(msg)
	unless(msg.isSelfMessage?)
	    if(msg.args[0]=~msg.selfNick)
		cmnd_notice(msg.server,msg.to,"Pls don't bother me...")
	    end
	end
    end
end

irc=BotExample.new
irc.open('irc.codehaus.org',['rica','Rica Example'],'rica_ex')
irc.thread.join
