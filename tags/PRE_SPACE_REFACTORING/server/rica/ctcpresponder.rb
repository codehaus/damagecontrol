#
# ctcpresponder.rb
#   -- rica ctcp auto responce
#   NISHI Takao <zophos@koka-in.org>
#
# $Id: ctcpresponder.rb,v 1.1 2004/05/17 14:41:23 tirsen Exp $
#
require 'rica'

module Rica
    
    ############################################################
    #
    # Ctcp responder class
    #
    # Sample code of Rica::MessageProcessor sub class.
    #
    class CtcpResponder<MessageProcessor
	VERSION=RICA_NAME+" "+RICA_VERION+" on Ruby "+String(RUBY_VERSION)
	USERINFO=[RICA_FULLNAME,RICA_INFO_URL]
	CLIENTINFO="ACTION CLIENTINFO ECHO PING TIME USERINFO VERSION"
	
	def initialize
	    super()
	    @clientinfo=CLIENTINFO
	    @userinfo=USERINFO
	    @version=VERSION
	end
	
	attr_accessor :userinfo
	attr_accessor :version
	
	def on_recv_cmnd_ctcp_query_clientinfo(msg)
	    ctcp_answer_clientinfo(msg.server,msg.fromNick,@clientinfo)
	end
	
	def on_recv_cmnd_ctcp_query_echo(msg)
	    ctcp_answer_echo(msg.server,msg.fromNick,msg.args[0])
	end
	
	def on_recv_cmnd_ctcp_query_ping(msg)
	    ctcp_answer_ping(msg.server,msg.fromNick,msg.args[0])
	end
	
	def on_recv_cmnd_ctcp_query_time(msg)
	    ctcp_answer_time(msg.server,msg.fromNick)
	end
	
	def on_recv_cmnd_ctcp_query_userinfo(msg)
	    ctcp_answer_userinfo(msg.server,msg.fromNick,@userinfo)
	end
	
	def on_recv_cmnd_ctcp_query_version(msg)
	    ctcp_answer_version(msg.server,msg.fromNick,@version)
	end
    end

end
