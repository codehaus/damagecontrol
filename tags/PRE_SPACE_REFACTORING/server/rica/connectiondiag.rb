#
# connectiondiag.rb
#   -- Rica Connection Diagnostic module
#   NISHI Takao <zophos@koka-in.org>
#
# $Id: connectiondiag.rb,v 1.1 2004/05/17 14:41:23 tirsen Exp $
#
require 'rica'
require 'timeout'

module Rica
    class Pinger
	include Event

	PING_INTERVAL_SEC=180
	
	def initialize(eventProc)
	    @eventProc=eventProc
	    @server=nil
	    @servername=nil
	    @queue=Queue.new
	    @thread=nil
	end

	def start
	    if(@thread.nil?)
		sendPing
	    end
	end

	def stop
	    unless(@thread.nil?)
		begin
		    @thread.kill
		rescue TreadError
		end
		@thread=nil
	    end
	end

	def default_action(msg)
	    @queue.push(msg)
	end

	def recv_on_link(msg)
	    #
	end

	def on_link_closed(msg)
	    self.stop
	end

	def on_recv_rpl_endofmotd(msg)
	    @server=msg.server
	    @servername=msg.from
	    self.start
	    self.default_action(msg)
	end
	alias on_recv_err_nomotd on_recv_rpl_endofmotd

	private
	def sendPing
	    @thread=Thread.start do
		loop do
		    begin
			timeout(PING_INTERVAL_SEC){
			    @queue.pop
			}
		    rescue
			if((!@server.nil?)&&(!@servername.nil?))
			    @eventProc.cmnd_ping(@server,@servername)
			end
		    end
		end
	    end
	end

    end

    class ConnectionDiag<MessageProcessor
	def initialize
	    super
	    @servers={}
	end
	
	def default_action(msg)
	    begin
		@servers[msg.server].dispatch(msg)
	    rescue NameError
	    end
	end
	
	def on_recv_rpl_endofmotd(msg)
	    unless(@servers.has_key?(msg.server))
		@servers[msg.server]=Pinger.new(self)
	    end
	    self.default_action(msg)
	end
	
	def on_recv_link_closed(msg)
	    self.default_action(msg)
	    @servers.delete(msg.server)
	end
    end
end
