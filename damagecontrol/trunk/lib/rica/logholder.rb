#
# logholder.rb
#   -- RICA event cacheing library
#   NISHI Takao <zophos@koka-in.org>
#
# $Id$
#
require 'rica'

module Rica

    ############################################################
    #
    # Irc Log Holding Modules
    #
    module LogHolder

	########################################################
	#
	# Channel mode class
	#   Some non-RFC1459 mode supported.
	#   (I, B and E)
	#
	class ChannelMode
	    include Event

	    MODE_LINE=['o','p','s','i','t','n','m',
		'l','b','v','k','I','B','E']

	    ####################################################
	    #
	    # constructor
	    #
	    # Args:
	    #   ChannelInfo
	    #
	    def initialize(channelInfo)
		clear
		@cinfo=channelInfo
	    end

	    ####################################################
	    #
	    # to_s override
	    #
	    # Return:
	    #   IRC message like strings. (eg. +stnl 10)
	    #
	    def to_s
		#
		# +o, +b, +v, +I, +B and +E modes are
		# ignored
		#
		modes=[nil,@p,@s,@i,@t,@n,@m,
		    @l,nil,@v,@k,nil,nil,nil]

		s=["+"]

		MODE_LINE.each{|c|
		    if(modes.shift)
			s[0]+=c
		    end
		}
		s.push(@l)
		s.push(@k)

		return s.join(" ").strip
	    end
	    
	    alias put dispatch

	    ####################################################
	    #
	    # MODE command
	    #
	    def on_recv_cmnd_mode(msg)
		purse(msg.args.dup)
	    end

	    ####################################################
	    #
	    # RPL_CHANNELMODEIS (324)
	    #
	    def on_recv_rpl_channelmodeis(msg)
		clear
		purse(msg.args[1..-1])
	    end

	    private

	    ####################################################
	    #
	    # all mode clear
	    #
	    def clear
		@o=nil
		@p=false
		@s=false
		@i=false
		@t=false
		@n=false
		@m=false
		@l=nil
		@b=nil
		@v=nil
		@k=nil
		@I=nil
		@B=nil
		@E=nil
	    end

	    ####################################################
	    #
	    # purse mode strings
	    #
	    def purse(modes)
		flag=false

		mstr=modes.shift
		while(mstr)
		    mchars=mstr.split('')
		    mchars.each{|c|
			case c
			when '+'
			    flag=true
			when '-'
			    flag=false
			when 'o'
			    nick=modes.shift
			    i=@cinfo.namesArray.index(nick)
			    begin
				if(flag)
				    @cinfo.namesArray[i].setOp
				else
				    @cinfo.namesArray[i].deOp
				end
			    rescue TypeError
			    end
			when 'p'
			    @p=flag
			when 's'
			    @s=flag
			when 'i'
			    @i=flag
			when 't'
			    @t=flag
			when 'n'
			    @n=flag
			when 'm'
			    @m=flag
			when 'l'
			    if(flag)
				@l=modes.shift
			    else
				@l=nil
			    end
			when 'b'
			    modes.shift
			when 'v'
			    nick=modes.shift
			    i=@cinfo.namesArray.index(nick)
			    begin
				if(flag)
				    @cinfo.namesArray[i].setVoice
				else
				    @cinfo.namesArray[i].deVoice
				end
			    rescue
			    end
			when 'k'
			    key=modes.shift
			    if(flag)
				@k=key
			    else
				@k=nil
			    end
			when 'I'
			    modes.shift
			when 'B'
			    modes.shift
			when 'E'
			    modes.shift
			end
		    }
		    mstr=modes.shift
		end
	    end
	end

	########################################################
	#
	# User mode class
	#   A non-RFC1459 mode 'f' supported.
	#
	class UserMode
	    include Event
	    
	    MODE_LINE=['i','s','w','o','f']

	    def initialize
		clear
	    end

	    ####################################################
	    #
	    # to_s override
	    #
	    # Return:
	    #   IRC message like strings. (eg. +if)
	    #
	    def to_s
		s='+'
		modes=[@i,@s,@w,@o,@f]
		
		MODE_LINE.each{|m|
		    if(modes.shift)
			s+=m
		    end
		}

		return s
	    end
	    
	    alias put dispatch

	    ####################################################
	    #
	    # MODE command
	    #
	    def on_recv_cmnd_mode(msg)
		purse(msg.args.dup)
	    end

	    ####################################################
	    #
	    # RPL_UMODEIS (221)
	    #
	    def on_recv_rpl_umodeis(msg)
		clear
		purse(msg.args.dup)
	    end
	    
	    private
	    
	    ####################################################
	    #
	    # all mode clear
	    #
	    def clear
		@i=false
		@s=false
		@w=false
		@o=false
		@f=false
	    end
	    
	    ####################################################
	    #
	    # purse mode string
	    #
	    def purse(modes)
		flag=false

		modes=modes.join('').split('')
		modes.each{|m|
		    case m
		    when '+'
			flag=true
		    when '-'
			flag=false
		    when 'i'
			@i=flag
		    when 's'
			@s=flag
		    when 'w'
			@w=flag
		    when 'o'
			@o=flag
		    when 'f'
			@f=flag
		    end
		}
	    end
	end
	
	########################################################
	#
	# Channel user Informations
	#
	# Nick and two mode(+o,+v) is kept.
	#
	class ChannelUserInfo
	    include Event

	    ####################################################
	    #
	    # constructor
	    #
	    # Args:
	    #   String nick
	    #
	    def initialize(nick)
		@o=false
		@v=false
		case nick[0].chr
		when '@'
		    @o=true
		    nick=nick[1..-1]
		when '+'
		    @v=true
		    nick=nick[1..-1]
		end
		@nick=nick
	    end
	    
	    attr_reader :nick
	    
	    ####################################################
	    #
	    # to_s override
	    #
	    # Return:
	    #   IRC message like strings. (eg. @hoge)
	    #
	    def to_s
		s=""
		if(@o)
		    s="@"
		elsif(@v)
		    s="+"
		end

		return s+@nick
	    end
	    
	    ####################################################
	    #
	    # == override
	    #
	    # Compare an object and me using @nick without case.
	    #
	    # This method use for Array#index or Array#delete. 
	    #
	    def ==(obj)
		begin
		    @nick.downcase==obj.downcase
		rescue NameError
		    @nick==obj
		end
	    end

	    ####################################################
	    #
	    # <=> override
	    #
	    # Compare an object and me using @nick with case.
	    #
	    # This method use for Array#sort.
	    #
	    def <=>(obj)
		return self.to_s<=>obj.to_s
	    end

	    ####################################################
	    #
	    # mode prefix
	    #
	    # Return :
	    #   String mode_prefix ('@'|'+'|'')
	    #
	    def mode
		if(@o)
		    "@"
		elsif(@v)
		    "+"
		else
		    ""
		end
	    end
	    
	    def isOp?
		return(@o)
	    end
	    
	    def isVoice?
		return(@o|@v)
	    end
	    
	    def setOp
		@o=true
	    end
	    
	    def setVoice
		@v=true
	    end
	    
	    def deOp
		@o=false
		@v=false
	    end
	    
	    def deVoice
		@v=false
	    end
	    
	    alias put dispatch
	    
	    def on_recv_cmnd_nick(msg)
		if(@nick==msg.fromNick)
		    @nick=msg.to
		end
	    end
	end
	
	########################################################
	#
	# Channel Informations
	#
	class ChannelInfo
	    include Event

	    ####################################################
	    #
	    # constructor
	    #
	    # Args:
	    #   server      :server name
	    #   channel     :channel name
	    #   console     :(true=server global information|
	    #                   false=channle local information)
	    #   logging_obj :logging object
	    #
	    # Note:
	    #   To logging, the logging_obj requires push() method.
	    #   If there is not push() method, log is not held.
	    #
	    def initialize(server,channel,console=false,logging_obj=nil)
		@server=server
		@channel=channel
		@topic=""
		@names=[]
		@names_tmp=[]

		#
		# is server global information?
		#
		@console=console
		
		#
		# if self keep server global information,
		# @mode keeps UserMode, else @mode keeps
		# ChannelMode
		#
		if(@console)
		    @mode=UserMode.new
		else
		    @mode=ChannelMode.new(self)
		end

		@log=logging_obj
	    end
	    
	    attr_reader :server
	    attr_reader :channel
	    attr_reader :console
	    attr_reader :topic
	    attr_reader :log
	    
	    ####################################################
	    #
	    # Is this buffer for priv?
	    #
	    # Return:
	    #   true|false
	    #
	    def isPrivBuffer?
		begin
		    case @channel.to_s[0].chr
		    when "#","&","!","%"
			return false
		    else
			return true
		    end
		rescue NameError
		    return nil
		end
	    end

	    ####################################################
	    #
	    # Channel user list
	    #
	    # Args:
	    #   prefix :additional prefix
	    #   suffix :additional suffix
	    #
	    # Return:
	    #   String nameslist like as ircd names reply
	    #
	    # Note:
	    #   When prefix or suffix given, each nick is added
            #   prefix or suffix.
	    #
	    def names(prefix="",suffix="")
		if(self.isPrivBuffer?)
		    return ""
		end

		if(prefix.empty? && suffix.empty?)
		    @names.join(" ")
		else
		    s=[]
		    @names.each{|n|
			s.push(n.mode+prefix+n.nick+suffix)
		    }
		    s.join(" ")
		end
	    end

	    def namesArray
		if(self.isPrivBuffer?)
		    return []
		else
		    return @names
		end
	    end

	    ####################################################
	    #
	    # Channel or user mode
	    #
	    # Return:
	    #   String channel or user mode
	    #
	    def mode
		if(self.isPrivBuffer?)
		    return ""
		else
		    return @mode.to_s
		end
	    end
	    
	    ####################################################
	    #
	    # message dispatch and logging
	    #
	    # When self.dispatch returns non-false or non-nil,
	    # the message is logged.
	    #
	    def put(msg)

		#
		# channel name is kept at Message.add_info
		#
		msg.add_info=[@channel.downcase]

		if(dispatch(msg))
		    begin
			@log.push(msg)
		    rescue NameError
		    end
		    return msg
		end
	    end
	    
	    ####################################################
	    #
	    # On default, the message is logged.
	    #
	    def default_action(msg)
		true
	    end

	    ####################################################
	    #
	    # If user who issued NICK command is in this channel,
	    # the message is logged.
	    #
	    def on_recv_cmnd_nick(msg)
		i=@names.index(msg.fromNick)
		unless(i.nil?)
		    return @names[i].put(msg)
		end
	    end

	    ####################################################
	    #
	    # If user who issued QUIT command is in this channel,
	    # the message is logged.
	    #
	    def on_recv_cmnd_quit(msg)
		@names.delete(msg.fromNick)
	    end

	    def on_recv_cmnd_join(msg)
		@names.unshift(ChannelUserInfo.new(msg.fromNick))
		true
	    end
	    
	    def on_recv_cmnd_part(msg)
		@names.delete(msg.fromNick)
	    end

	    def on_recv_cmnd_mode(msg)
		@mode.put(msg)
		true
	    end

	    def on_recv_cmnd_topic(msg)
		@topic=msg.args[0]
		true
	    end

	    def on_recv_cmnd_kick(msg)
		@names.delete(msg.args[0])
	    end

	    def on_recv_rpl_umodeis(msg)
		if(@console)
		    @mode.put(msg)
		    return true
		else
		    return false
		end
	    end

	    def on_recv_rpl_channelmodeis(msg)
		unless(@console)
		    @mode.put(msg)
		    return true
		else
		    return false
		end
	    end

	    def on_recv_rpl_notopic(msg)
		@topic=""
		true
	    end

	    def on_recv_rpl_topic(msg)
		@topic=msg.args[1]
		true
	    end

	    def on_recv_rpl_namreply(msg)
		#@names.clear
		msg.args[2].strip.split(" ").each{|nick|
		    @names_tmp.push(ChannelUserInfo.new(nick))
		}
		true
	    end

	    def on_recv_rpl_endofname(msg)
		@names=@names_tmp.dup
		@names_tmp.clear
		true
	    end
	end

	########################################################
	#
	# Server Informations
	#
	class ServerInfo
	    include Event
	    
	    SERVER_COMMON_BUF=""

	    ####################################################
	    #
	    # constructor
	    #
	    # Args:
	    #   server        :server_name
	    #   logging_class :Ruby class for logging
            #   logging_opt   :arguments for logging_class.new
	    #
	    def initialize(server,logging_class=nil,*logging_opt)
		@server=server
		@channels={}
		@logging_class=logging_class
		@logging_opt=*logging_opt

		#
		# Create global information holder
		#
		begin
		    @channels[SERVER_COMMON_BUF]=
			ChannelInfo.new(@server,
					SERVER_COMMON_BUF,
					true,
					@logging_class.new(*@logging_opt)
					)
		rescue NameError,ArgumentError
		    @channels[SERVER_COMMON_BUF]=
			ChannelInfo.new(@server,
					SERVER_COMMON_BUF,
					true,
					nil
					)
		end
	    end
	    
	    attr_reader :channels

	    def [](channel)
		@channels[channel.downcase]
	    end

	    ####################################################
	    #
	    # get server global information holder
	    #
	    # Return :ChannelInfo server global messages
	    #
	    def console
		return @channels[SERVER_COMMON_BUF]
	    end

	    ####################################################
	    #
	    # get channel list
	    #
	    # Return :ChannelInfo server global messages
	    #
	    def channel_list
		tmp=@channels.keys
		tmp.delete(SERVER_COMMON_BUF)
		tmp
	    end

	    ####################################################
	    #
	    # purge channel information
	    #
	    def purge_channel(channel)
		@channels.delete(channel.downcase)
	    end

	    ####################################################
	    #
	    # get user mode
	    #
	    # Return :UserMode
	    #
	    def mode
		return @channels[SERVER_COMMON_BUF].mode
	    end

	    ####################################################
	    #
	    # Message dispatch methods
	    #
	    def put(msg)
		if(msg.server==@server)
		    dispatch(msg)
		end
	    end

	    ####################################################
	    #
	    # On defualt, given messges send to global
	    # information holder.
	    #
	    def default_action(msg)
		@channels[SERVER_COMMON_BUF].put(msg)
	    end
	    
	    def on_recv_cmnd_pong(msg)
		#nop
	    end
	    
	    ####################################################
	    #
	    # NICK and QUIT command messages are send to
	    # every holders.
	    #
	    def on_recv_cmnd_nick(msg)
		broadcast(msg)
	    end
	    alias on_recv_cmnd_quit on_recv_cmnd_nick

	    def on_recv_cmnd_join(msg)
		put_to(msg.args[0],msg)
	    end
	    
	    def on_recv_cmnd_part(msg)
		put_to(msg.to,msg)
	    end
	    
	    def on_recv_cmnd_mode(msg)
		#
		# if usermode changed, the message is send to
		# global information holder.
		#
		if(msg.to==msg.selfNick)
		    @channels[SERVER_COMMON_BUF].put(msg)
		else
		    put_to(msg.to,msg)
		end
	    end

	    def on_recv_cmnd_topic(msg)
		put_to(msg.to,msg)
	    end

	    def on_recv_cmnd_kick(msg)
		put_to(msg.to,msg)
	    end

	    def on_recv_cmnd_privmsg(msg)
		#
		# When recept Priv, the message goes
		# to sender's holder.
		#
		if(msg.isPriv? && !msg.isSelfMessage?)
		    put_to(msg.fromNick,msg)
		else
		    put_to(msg.to,msg)
		end
	    end
	    alias on_recv_cmnd_notice on_recv_cmnd_privmsg
	    
	    def on_recv_rpl_umodeis(msg)
		@channels[SERVER_COMMON_BUF].put(msg)
	    end

	    def on_recv_rpl_channelmodeis(msg)
		put_to(msg.args[0],msg)
	    end

	    def on_recv_rpl_notopic(msg)
		put_to(msg.args[0],msg)
	    end

	    def on_recv_rpl_topic(msg)
		put_to(msg.args[0],msg)
	    end

	    #def on_recv_rpl_inviting(msg)
	    #end
	    
	    def on_recv_rpl_namreply(msg)
		put_to(msg.args[1],msg)
	    end
	    
	    def on_recv_rpl_endofname(msg)
		put_to(msg.args[0],msg)
	    end

	    def on_recv_rpl_banlist(msg)
		put_to(msg.args[0],msg)
	    end
	    
	    def on_recv_rpl_endofbanlist(msg)
		put_to(msg.args[0],msg)
	    end

	    def on_recv_err_cannotsendtochan(msg)
		put_to(msg.args[0],msg)
	    end

	    def on_recv_err_chanopprivsneeded(msg)
		put_to(msg.args[0],msg)
	    end

	    private

	    ####################################################
	    #
	    # broadcast to every holders.
	    #
	    def broadcast(msg)
		buf=[]
		@channels.each{|key,val|
		    if(val.put(msg))
			buf.push(key)
		    end
		}
		msg.add_info=buf
		return msg
	    end

	    ####################################################
	    #
	    # send message to specified holder.
	    #
	    def put_to(channel,msg)
		ch=channel.to_s.downcase

		#
		# If given channel information holder does
		# not exist, create it first.
		#
		unless(@channels.has_key?(ch))
		    begin
			@channels[ch]=
			    ChannelInfo.new(@server,
					channel,
					false,
					@logging_class.new(*@logging_opt)
					)
		    rescue NameError
			@channels[ch]=
			    ChannelInfo.new(@server,
					channel,
					false,
					nil
					)
		    end
		end

		@channels[ch].put(msg)
	    end

	end
	
	########################################################
	#
	# Logger Main
	#
	class Logger<MessageProcessor
	    
	    ####################################################
	    # 
	    # constructor
	    #
	    # Args:
	    #   logging_class :Ruby class for logging
	    #   logging_opt   :arguments for logging_class.new
	    #
	    def initialize(logging_class=nil,*logging_opt)
		@servers={}
		@logging_class=logging_class
		@logging_opt=*logging_opt
		super()
	    end
	    
	    attr_reader :servers

	    def [](server)
		@servers[server.downcase]
	    end
	    
	    ####################################################
	    # 
	    # All messages incoming this class are send to
	    # each ServerInfo instance
	    #
	    def default_action(msg)

		#
		# If target ServerInfo instance does not exist,
		# create first.
		#
		unless(@servers.has_key?(msg.server))
		    @servers[msg.server]=
			ServerInfo.new(
				       msg.server,
				       @logging_class,
				       *@logging_opt
				       )
		end
		@servers[msg.server].put(msg)
	    end
	    
	    def on_recv_cmnd_join(msg)
		if(msg.isSelfMessage?)
		    self.cmnd_mode(msg.server,msg.args[0])
		end
		self.default_action(msg)
	    end

	    def on_recv_rpl_endofmotd(msg)
		self.cmnd_mode(msg.server,msg.selfNick)
		self.default_action(msg)
	    end

	    def on_recv_err_nomotd(msg)
		self.cmnd_mode(msg.server,msg.selfNick)
		self.default_action(msg)
	    end
	end

    end

end

=begin
logger=Rica::LogHolder::Logger.new(Array)
logger.open('localhost',['zophos','NISHI Takao'],'zophos')

logger.thread.join
=end
