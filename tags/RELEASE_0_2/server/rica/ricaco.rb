#!/usr/bin/ruby -d
#
# ricaco.rb
#   -- rica sample code
#   NISHI Takao <zophos@koka-in.org>
#
# $Id: ricaco.rb,v 1.1 2004/05/17 14:41:23 tirsen Exp $
#
require 'rica'
require 'ctcpresponder'
require 'jcode'
require 'curses'

class Ricaco<Rica::MessageProcessor
    include Curses

    TALK_LINES=3

    def initialize
	super()

	@logininfo={}
	@justbeforemsg=""

	@msgbuf=Array.new
	@cur_lines=0

	init_screen
	nonl
	crmode
	cbreak
	noecho

	@view_lines=lines-TALK_LINES
	@view_cols=cols-1
	@view=Window.new(@view_lines,@view_cols,0,0)
	@view.setpos(0,0)
	@talk=Window.new(2,@view_cols,@view_lines+1,0)
	@talk.setpos(1,0)

	@currentServer=""
	@currentChnl=""
	
	@instr=""
	@strq=Queue.new
	Thread.new{
	    getstrloop
	}
    end

    attr_accessor :currentServer
    attr_accessor :currentChnl

    def default_action(msg)
	putstr(msg.string("%T %s %t:%f %C %a"))
    end

    def on_link_established(msg)
	@currentServer=msg.server
	@currentChnl=""
	putstr(msg.string("%T %s Link Established"))
	if(@logininfo.has_key?(msg.server))
	    @logininfo[msg.server].each{|c|
		cmnd_join(msg.server,c)
	    }
	else
	    @logininfo[msg.server]=[]
	end
    end

    def on_link_failed(msg)
	putstr(msg.string("%T %s Link Failed"))
    end

    def on_link_closed(msg)
	@currentServer=""
	@currentChnl=""
	putstr(msg.string("%T %s Link Closed"))

	#
	# auto reopen
	#
	if(connections.include?(msg.server))
	    Thread.start{
		sleep(5)
		reopen(msg.server)
	    }
	end
    end
    
    def on_recv_rpl_endofmotd(msg)
	putstr(msg.string("%T %s %t:%f %C %a\n"))
    end

    def on_recv_cmnd_quit(msg)
	if(msg.isSelfMessage?)
	    putstr(msg.string("%T %s QUIT"))
	else
	    self.default_action(msg)
	end
	
    end

    #
    # Sometime, IRCnet's server provides 'PONG' message.
    # Why?
    #
    def on_recv_cmnd_ping(msg)
	#
	# NOP
	# 
    end
    alias on_recv_cmnd_pong on_recv_cmnd_ping

    def on_recv_cmnd_privmsg(msg)
	
	#
	# Don't show same message
	#
	testmsg=msg.string("%t:%f %a")
	if(@justbeforemsg==testmsg)
	    return
	end
	@justbeforemsg=testmsg

	if(msg.isSelfMessage?)
	    if(msg.isPriv?)
		putstr(msg.string("%T %s >%t< %a"))
	    else
		putstr(msg.string("%T %s >%t:%f< %a"))
	    end
	else
	    if(msg.isPriv?)
		putstr(msg.string("%T %s =%f= %a"))
	    else
		putstr(msg.string("%T %s <%t:%f> %a"))
	    end
	end
    end
    alias on_recv_cmnd_notice on_recv_cmnd_privmsg

    def on_recv_cmnd_join(msg)
	if(msg.isSelfMessage?)
	    @currentServer=msg.server
	    @currentChnl=String(msg.args[0]).strip
	    @logininfo[msg.server].push(@currentChnl)
	    @logininfo[msg.server].uniq!
	end
	putstr(msg.string("%T %s %t:%f %C %a"))
    end

    def on_recv_cmnd_part(msg)
	if(msg.isSelfMessage?)
	    @logininfo[msg.server].delete(msg.to)
	end
	putstr(msg.string("%T %s %t:%f %C %a"))
    end

    def getstr
	#return @talk.getstr
	return @strq.pop
    end
    
    def putstr(msg)
	until(msg.empty?)
	    msg=addstrWithScrool(msg)
	end
	@view.refresh

	show_prompt
    end

    def prompt
	show_prompt

	msg=Kconv::toeuc(self.getstr)
	msg.chomp!

	unless(msg.empty?)
	    #
	    # /hoge (except //hoge) is assumed as command 'hoge'.
	    # //hoge is treated as message '/hoge'.
	    #
	    if(msg=~/^\/([^\/].+)/)
		unless(exec_cmnd($1))
		    return false
		end
	    else
		if(msg=~/^\/(.+)/)
		    msg=$1
		end
		if((!@currentChnl.empty?)&&(!@currentServer.empty?))
		    self.cmnd_privmsg(@currentServer,@currentChnl,msg)
		end
	    end
	end

	return true
    end
    
    private

    #
    #
    #
    def getstrloop
	loop do
	    c=@talk.getch
	    case c
	    when 8 # ^H
		@instr.chop!
	    when 13 # ^M
		@strq.push(@instr)
		@instr=""
	    when 27 # ^[
		@talk.getch
		@talk.getch
	    when 127
		@instr.chop!
	    else
		@instr+=c.chr
		if(c>127)
		    @instr+=@talk.getch.chr
		end
	    end
	    show_prompt
	end
    end

    #
    # line-breaking and scrooling supported 2byte chars
    #
    def addstrWithScrool(msg)
	orgmsg=msg
	while(msg.size>=@view_cols)
	    msg=msg.chop
	end
	if(orgmsg==msg)
	    orgmsg=""
	else
	    orgmsg=orgmsg[msg.size..-1]
	end

	@msgbuf.push(msg+"\n")
	@cur_lines+=1

	if(@cur_lines<@view_lines)
	    @view.setpos(@cur_lines-1,0)
	    @view.addstr(msg+"\n")
	else
	    while(@cur_lines>=@view_lines)
		tmp=@msgbuf.shift
		@cur_lines-=1
	    end

	    i=0
	    @msgbuf.each{|m|
		@view.setpos(i,0)
		@view.addstr(m)
		i+=1
	    }
	end

	return orgmsg
    end
    
    def show_prompt
	p=prompt_str
	@talk.addstr(@instr+"\n")
	@talk.setpos(0,p.size+@instr.size)
	@talk.refresh
    end
    
    def prompt_str
	str=String(@currentChnl)+"@"+String(@currentServer)
	if(str=="@")
	    str=""
	end
	str+="> "

	@talk.setpos(0,0)
	@talk.standout
	@talk.addstr(str)
	@talk.standend

	return str
    end

    # commands:
    #   connect to server:
    #        open @server:port:passwd:alias nick username real_name
    #
    #   close connection of server:
    #        quit @server
    #
    #   quit this program:
    #        quitall or exit
    #
    #   issue irc_command to server:
    #        irc_command @server irc command arguments
    #
    def exec_cmnd(msg)

	tmp=msg.strip.split(" ",3)
	cmnd=String(tmp.shift)
	server=String(@currentServer)
	args=""
	if(cmnd=~/([^\@]+)\@(.+)/)
	    cmnd=$1
	    tmp.unshift("@"+$2)
	end
	unless(tmp[0].nil?)
	    if(tmp[0][0].chr=='@')
		server=String(tmp.shift)
		server=server[1..-1]
	    end
	    args=String(tmp.join(" "))
	end

	case cmnd.upcase
	when "C"
	    if(args=~/([^\@]+)\@(.+)/)
		@currentServer=$2
		@currentChnl=$1
	    else
		@currentChnl=args
	    end
	when "S"
	    @currentChannel=""
	    if(server!=@currentServer)
		@currentServer=server
	    else
		@currentServer=args
	    end
	when "P"
	    tmp=args.split(" ",2)
	    if((!server.empty?)&&(!tmp[0].nil?))
		@currentServer=server
		@currentChnl=String(tmp[0])
		cmnd_privmsg(server,String(tmp[0]),String(tmp[1]))
	    end
	when "OPEN"
	    tmp=args.split(" ",2)
	    if(tmp.empty?)
		return true
	    end
	    args=String(tmp[1])
	    server=String(tmp[0])
	    
	    tmp=server.split(":",4)
	    server=tmp[0]
	    port=6667
	    unless(tmp[1].nil?)
		port=tmp[1].to_i
	    end
	    passwd=String(tmp[2])
	    serveralias=tmp[3]
	
	    tmp=args.strip.split(" ",3)
	    nick=String(tmp[0])
	    user=String(tmp[1])
	    realname=String(tmp[2])
	    
	    if(user.empty?)
		user=nick
	    end
	    if(realname.empty?)
		realname=user
	    end
	    
	    open([server,port,passwd,serveralias],[user,realname],nick)

	when "EXIT","QUITALL"
	    closeAll
	    return false
	else
	    if((!server.empty?)&&(!cmnd.empty?))
		directcommand(server,(cmnd+" "+args).strip)
	    end
	end
	
	return true
    end
end


irc=Ricaco.new
ctcp=Rica::CtcpResponder.new
ctcp.version="Ricaco 0.3 with "+ctcp.version
#
# loop until input "/exit"
#
while(irc.prompt)
end

exit
