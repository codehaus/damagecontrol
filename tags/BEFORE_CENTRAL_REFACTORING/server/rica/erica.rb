#!/usr/bin/ruby -d
#
# erica
#   -- End user interface for RICA
#   NISHI Takao <zophos@koka-in.org>
#
# $Id: erica.rb,v 1.1 2004/05/17 14:41:23 tirsen Exp $
#

require 'gtk'
require 'rica'
require 'connectiondiag'
require 'ctcpresponder'
require 'logholder'

include Rica

ERICA_DEFAULT_TITLE='erica'
ERICA_DEFAULT_TREE_WIDTH=100
ERICA_DEFAULT_TREE_HEIGHT=400
ERICA_DEFAULT_CLOG_WIDTH=400
ERICA_DEFAULT_CLOG_HEIGHT=250
ERICA_DEFAULT_WIDTH=500
ERICA_DEFAULT_HEIGHT=400

################################################
#
# Resouces
#
class Resouces
    include Singleton

    RESOUCE_SEARCH_PATH=[".",ENV["HOME"]]
    GTK_RESOUCE_FILE=".gtkrc"

    def initialize
	load

	@fontset=nil
	@tscolor=Gdk::Color.new(0,0,65535)
	@nickcolor=Gdk::Color.new(0,32767,0)
	@systemcolor=Gdk::Color.new(0,32767,0)
	@msgcolor=nil
	@bgcolor=nil
    end

    attr_accessor :fontset
    attr_accessor :tscolor
    attr_accessor :nickcolor
    attr_accessor :systemcolor
    attr_accessor :msgcolor
    attr_accessor :bgcolor

    def load
	RESOUCE_SEARCH_PATH.each{|path|
	    f=path.to_s+"/"+GTK_RESOUCE_FILE
	    if(FileTest::exist?(f))
		Gtk::RC.parse(f)
		break
	    end
	}
    end
end


################################################
#
# Servers, channels and users tree
#  (Gtk::Tree wrapper)
#
class BuffersTree<Gtk::ScrolledWindow
    include Event
    
    def initialize(buffer)
	@buffer=buffer

	@node=Hash.new
	@node["/"]=Gtk::Tree.new
	@node["/"].set_selection_mode(Gtk::SELECTION_SINGLE)
	@node["/"].show

	super()
	self.add_with_viewport(@node["/"])
	self.show

	@contents=Hash.new
	@selection=[]
    end

    def selectElement(*elements)
	el=getElement(*elements)
	unless(el.nil?)
	    @selection.push(el)
	    @selection.uniq!
	    el.select
	end
    end

    def deselectElement(*elements)
	el=getElement(*elements)
	unless(el.nil?)
	    el.deselect
	    @selection.delete(el)
	end
    end

    def selectSingleElement(*elements)
	@selection.each{|el|
	    begin
		el.deselect
	    rescue ArgumentError
	    end
	}
	@selection.clear
	selectElement(*elements)
    end

    alias push dispatch

    #
    # override methods of Rica::Event
    #
    def on_link_established(msg)
	addElement(msg.server)
    end

    def on_link_closed(msg)
	removeElement(msg.server)
    end

    def on_recv_cmnd_nick(msg)
	msg.add_info.each{|ch|
	    refreshNames(msg.server,ch)
	}
    end

    def on_recv_cmnd_quit(msg)
	if(msg.isSelfMessage?)
	    removeElement(msg.server)
	else
	    msg.add_info.each{|ch|
		removeElement(msg.server,ch,msg.fromNick)
	    }
	end
    end

    def on_recv_cmnd_join(msg)
	if(msg.isSelfMessage?)
	    addElement(msg.server,msg.to)
	    showElement(msg.server,msg.to)
	else
	    refreshNames(msg.server,msg.add_info[0].to_s)
	end
    end

    def on_recv_cmnd_part(msg)
	if(msg.isSelfMessage?)
	    removeElement(msg.server,msg.to)
	else
	    removeElement(msg.server,msg.to,msg.fromNick)
	end
    end
    
    def on_recv_cmnd_mode(msg)
	refreshNames(msg.server,msg.to)
    end

    def on_recv_cmnd_kick(msg)
	if(msg.to==msg.selfNick)
	    removeElement(msg.server,msg.to)
	else
	    removeElement(msg.server,msg.to,msg.args[0])
	end
    end
    
    def on_recv_cmnd_privmsg(msg)
	s=msg.server.to_s
	c=msg.to.to_s
	if((msg.isPriv?)&&(!msg.isSelfMessage?))
	    c=msg.fromNick
	end

	unless(hasElement?(s,c))
	    unless(c.empty?)
		addElement(s,c)
		showElement(s,c)
	    end
	end
    end
    alias on_recv_cmnd_notice on_recv_cmnd_privmsg

    def on_recv_rpl_endofname(msg)
	refreshNames(msg.server,msg.add_info[0].to_s)
    end

    private
    def hasElement?(*elements)
	if(getElement(*elements))
	    return true
	else
	    return false
	end
    end

    def getElement(*elements)
	el="/"+elements.join("/").downcase
	return @contents[el]
    end

    def getParent(*elements)
	elements.pop
	el="/"+elements.join("/").downcase
	return @node[el]
    end

    def addElement(*elements)
	buf=elements.dup
	str=buf.pop

	node="/"+buf.join("/").downcase
	el="/"+elements.join("/").downcase
	if(str.instance_of?(LogHolder::ChannelUserInfo))
	    el=node+"/"+str.nick.downcase
	end
	str=String(str)

	if(@contents.has_key?(el))
	    return
	end
	if(buf.size>0)
	    addElement(*buf)
	end

	@contents[el]=Gtk::TreeItem.new(str)
	@contents[el].signal_connect('select'){|widget|
	    begin
		@selection.each{|el|
		    unless(el==widget)
			el.deselect
		    end
		}
		@selection=[widget]
		@buffer.body.notify_signal(self,'select',*elements)
	    rescue NameError
	    end
	}
	@contents[el].signal_connect('deselect'){|widget|
	    @selection.delete(widget)
	}
	@contents[el].show

	unless(@node.has_key?(node))
	    @node[node]=Gtk::Tree.new
	    @node[node].set_selection_mode(Gtk::SELECTION_SINGLE)
	    @contents[node].set_subtree(@node[node])
	end
	@node[node].append(@contents[el])
    end

    def removeChild(*elements)
	nd="/"+elements.join("/").downcase
	n=@node[nd]
	if(n.nil?)
	    return
	end

	tag="^"+nd+"/"
	keys=@contents.keys
	keys.each{|i|
	    if(i=~tag)
		if(@node.has_key?(i))
		    x=i.split("/")
		    removeChild(*x)
		end
		begin
		    n.remove_item(@contents[i])
		rescue
		end
		@contents.delete(i)
		@contents.rehash
	    end
	}

	@node.delete(nd)
	@node.rehash
    end

    def removeElement(*elements)
	removeChild(*elements)

	el="/"+elements.join("/").downcase
	elements.pop
	nd="/"+elements.join("/").downcase
	
	n=@node[nd]
	i=@contents[el]
	if((n.nil?)||(i.nil?))
	    return
	end
	
	n.remove_item(i)
	@contents.delete(el)

	@contents.rehash
    end

    def showElement(*elements)
	while(elements.size>0)
	    el=getElement(*elements)
	    unless(el.nil?)
		el.expand
	    end
	    elements.pop
	end
    end

    def refreshNames(server,channel)
	begin
	    buf=@buffer[server][channel].namesArray
	    el=getElement(server,channel)
	    exp=nil
	    if(el.instance_of?(Gtk::TreeItem))
		exp=el.expanded?
	    end
	    removeChild(server,channel)
	    buf.sort.each{|nick|
		addElement(server,channel,nick)
	    }
	    if(exp)
		el.expand
	    end
	rescue NameError
	end
    end
end


################################################
#
# Common Log area
#  (Gtk::Text wrapper)
#
class LogArea<Gtk::HBox
    MAX_LOG_SIZE=32768		#32KB
    EXPIRE_LOG_SIZE=16384	#16KB

    def initialize(autofreeze=false)
	@active=false
	@autofreeze=autofreeze

	@vadj=Gtk::Adjustment.new(0,0,0,0,0,0)
	@vs=Gtk::VScrollbar.new(@vadj)
	@vs.show
	@textarea=Gtk::Text.new(nil, @vadj)
	@textarea.set_editable(false)
	@textarea.show

	super(false,0)
	self.pack_start(@textarea,true,true,0)
	self.pack_start(@vs,false,false,0)
	self.show

	@lastmsg=nil

	@fontset=nil
	@tscolor=Gdk::Color.new(0,0,65535)
	@nickcolor=Gdk::Color.new(0,32767,0)
	@systemcolor=Gdk::Color.new(0,32767,0)
	@msgcolor=nil
	@bgcolor=nil
    end

    attr_accessor :active

    def scrolled?
	if(@vadj.value==@vadj.upper-@vadj.page_size)
	    return false
	else
	    return true
	end
    end

    def clear
	@textarea.delete_text(0,@textarea.get_length)
    end

    def appendLine(ircMessage,showts=true,showchannel=true,uniq=true)
	if(uniq)
	    begin
		if(@lastmsg.string("%H:%M:%S %t:%f %o")==
		   ircMessage.string("%H:%M:%S %t:%f %o"))
		    return
		end
	    rescue NameError
	    end
	    @lastmsg=ircMessage
	end

	freezing=false
	if(@autofreeze&&@active&&self.scrolled?)
	    freezing=true
	    @textarea.freeze
	end

	if(showts)
	    @textarea.insert(@fontset,@tscolor,@bgcolor,
			     ircMessage.timestamp.strftime("%H:%M "))
	end
	case ircMessage.command
	when Event::RECV_CMND_PRIVMSG,Event::RECV_CMND_NOTICE
	    prifix="<"
	    suffix=">"
	    if(ircMessage.isSelfMessage?)
		prifix=">"
		suffix="<"
	    elsif(ircMessage.isPriv?)
		prifix="="
		suffix="="
	    end
	    @textarea.insert(@fontset,@nickcolor,@bgcolor,prifix)
	    if(showchannel)
		@textarea.insert(@fontset,@nickcolor,@bgcolor,
				 ircMessage.to.to_s+"@"+
				 ircMessage.server.to_s+" ")
	    end
	    @textarea.insert(@fontset,@nickcolor,@bgcolor,
			     ircMessage.fromNick.to_s+suffix+" ")
	    
	    @textarea.insert(@fontset,@msgcolor,@bgcolor,
			     ircMessage.string("%a"))
	else
	    if(showchannel)
		@textarea.insert(@fontset,@systemcolor,@bgcolor,
			ircMessage.string("*** %s %t:%f %C %a"))
	    else
		@textarea.insert(@fontset,@systemcolor,@bgcolor,
			ircMessage.string("*** %f %C %a"))
	    end
	end
	@textarea.insert(@fontset,@msgcolor,@bgcolor,"\n")

	if(@textarea.get_length>MAX_LOG_SIZE)
	    if(@active&&(!freezing))
		freezing=true
		@textarea.freeze
	    end
	    @textarea.delete_text(0,EXPIRE_LOG_SIZE)
	    @textarea.set_point(@textarea.get_length)
	end

	if(@active&&freezing)
	    @textarea.thaw
	end
    end
end


################################################
#
# Log buffer
#  (CommonLogArea and Gtk::Label wrapper)
#
# This class is used for log buffering
#
class LogBuffer<Gtk::VBox
    include Rica::Event

    def initialize
	@topicarea=Gtk::Label.new(ERICA_DEFAULT_TITLE)
	@topicarea.jtype=Gtk::JUSTIFY_LEFT
	@topicarea.show

	@logarea=LogArea.new(true)

	super(false,0)
	self.pack_start(@topicarea,false,true,0)
	self.pack_start(@logarea,true,true,0)
	self.show

	@buffer=nil
	@server=""
	@channel=""
	@nick=""

	@show_timestamp=true
	@show_channel=false
    end

    attr_accessor :show_timestamp
    attr_accessor :show_channel

    def active=(x)
	@logarea.active=x
    end

    def scrolled?
	return @logarea.scrolled?
    end

    def bind(buffer)
	@buffer=buffer
	@server=buffer.server
	@channel=buffer.channel
    end

    def push(msg)
	@nick=msg.selfNick
	dispatch(msg)
	@logarea.appendLine(msg,@show_timestamp,@show_channel)
    end

    def refresh
	setTopic
    end

    def on_recv_cmnd_join(msg)
	if(msg.isSelfMessage?)
	    @server=msg.server
	    @channel=msg.to
	    setTopic
	end
    end

    def on_recv_cmnd_topic(msg)
	setTopic
    end
    def on_recv_cmnd_mode(msg)
	setTopic
    end
    def on_recv_rpl_umodeis(msg)
	setTopic
    end
    def on_recv_rpl_channelmodeis(msg)
	setTopic
    end
    def on_recv_rpl_notopic(msg)
	setTopic
    end
    def on_recv_rpl_topic(msg)
	setTopic
    end

    private
    def setTopic
	begin
	    if(@buffer.console)
		c=@nick
	    else
		c=@channel
	    end
	    @topicarea.set(sprintf("%s@%s[%s] %s",
				   c,
				   @server,
				   @buffer.mode,
				   @buffer.topic)
			   )
	rescue NameError,TypeError
	    if(@channel.empty?&&@server.empty?)
		@topicarea.set(ERICA_DEFAULT_TITLE)
	    else
		@topicarea.set(sprintf("%s@%s[]",
				       @channel,
				       @server)
			       )
	    end
	end
    end

end


################################################
#
# Current talking channel log area
#  (Gtk::Notebook wrapper)
#
class CurrentChannelArea<Gtk::Notebook
    def initialize(buffer)
	@buffer=buffer

	@console=LogBuffer.new	

	super()
	self.set_show_tabs(false)
	self.set_show_border(false)
	self.insert_page(@console,nil,0)
	self.show

	@server=nil
	@channel=nil
    end	   

    attr_reader :console
    attr_reader :server
    attr_reader :channel

    def setActiveBuffer(server,channel)
	unless(@server.to_s.downcase==server.to_s.downcase&&
	       @channel.to_s.downcase==channel.to_s.downcase)

	    self.get_nth_page(self.get_current_page).active=false

	    @server=server
	    @channel=channel
	    l=nil
	    if(server.to_s.empty?&&channel.to_s.empty?)
		l=@console
	    else
		l=@buffer[@server][@channel].log
	    end

	    p=self.page_num(l)
	    if(p>=0)
		self.set_page(p)
		l.active=true
		l.refresh
	    else
		l.bind(@buffer[@server][@channel])
		l.active=true
		self.insert_page(l,nil,0)
		self.set_page(0)
	    end
	end
    end

    def write(msg)
	if(msg.server.downcase==@server.to_s.downcase)
	    begin
		if(msg.add_info.index(@channel.to_s.downcase))
		    if(msg.add_info.size>1)
			return nil
		    else
			if(self.get_nth_page(self.get_current_page).scrolled?)
			    return false
			else
			    return true
			end
		    end
		end
	    rescue NameError
		return false
	    end
	end
	return false
    end

end


################################################
#
# Entry Area
# (Gtk::Entry wrapper and command parser)
#
class EntryArea<Gtk::Entry
    def initialize(buffer)
	@buffer=buffer

	super()
	self.signal_connect('activate'){|widget|
	    parse(self.get_text)
	    self.set_text("")
	}
	self.show
    end

    private
    def parse(str)
	server=@buffer.getCurrentServer
	channel=@buffer.getCurrentChannel

	str.split("\n").each{|s|
	    unless(s.empty?)
		#
		# /hoge (except //hoge) is assumed as command 'hoge'.
		# //hoge is treated as message '/hoge'.
		#
		if(s=~/^\/([^\/].+)/)
		    exec_cmnd(@buffer,server,channel,$1.to_s)
		else
		    if(s=~/^\/(.+)/)
			s=$1.to_s
		    end
		    unless(server.to_s.empty?)
			@buffer.cmnd_privmsg(server,channel,s)
		    end
		end
	    end
	}
    end
	
    def exec_cmnd(buffer,server,channel,str)
	cmndAr=str.strip.split(" ")

	case cmndAr[0].to_s.upcase

	when "OPEN"
	    #
	    # /OPEN SERVER:port:passwd:alias NICK:login:real name
	    #
	    server=""
	    port=6667
	    passwd=""
	    serveralias=nil
	    nick=""
	    user=""
	    realname=""

	    begin
		tmp=cmndAr[1].split(":",4)
		server=tmp[0]
		unless(tmp[1].nil?)
		    port=tmp[1].to_i
		end
		passwd=tmp[2].to_s
		serveralias=tmp[3]
	    
		cmndAr[2]=cmndAr[2..-1].join(" ")
		tmp=cmndAr[2].split(":",3)
		nick=tmp[0].to_s
		user=tmp[1].to_s
		realname=tmp[2].to_s
		
		if(user.empty?)
		    user=nick
		end
		if(realname.empty?)
		    realname=user
		end
	    rescue NameError
		return false
	    end
	    
	    return buffer.open([server,port,passwd,serveralias],
			       [user,realname],
			       nick)
	when "CLOSE"
	    #
	    # /CLOSE server
	    #
	    unless(cmndAr[1].nil?)
		server=cmndAr[1].to_s
	    end
	    return buffer.close(server)

	when "EXIT"
	    return buffer.exit
	else
	    return buffer.directcommand(server,str)
	end
    end
end


################################################
#
# Buffers Controle Base
#
class BuffersControler<Gtk::HBox
    include Rica::Event

    def initialize(buffer)
	@buffer=buffer

	@tree=BuffersTree.new(@buffer)
	@currentLog=CurrentChannelArea.new(@buffer)
	@entry=EntryArea.new(@buffer)
	@otherLog=LogArea.new(false)
	@otherLog.active=true

	super(false,0)
	self.pack_start(self.layout,true,true,0)
	self.show
	
	@currentServer=nil
	@currentChnl=nil
    end

    attr_reader :tree
    attr_reader :currentLog
    attr_reader :entry
    attr_reader :otherLog

    attr_reader :currentServer
    attr_reader :currentChnl

    def layout
	buf=Array.new

	buf.push(Gtk::HPaned.new)
	buf[-1].show

	buf[-1].add(@tree)

	buf.push(Gtk::VPaned.new)
	buf[-1].show
	buf.push(Gtk::VBox.new(false,0))
	buf[-1].show
	buf[-1].pack_start(@currentLog,true,true,0)
	buf[-1].pack_start(@entry,false,false,0)
	tmp=buf.pop
	buf[-1].add(tmp)
	buf[-1].add(@otherLog)
	tmp=buf.pop
	buf[-1].add(tmp)

	return buf[0]
    end

    def isCurrentChnl?(server,channel)
	ret=false
	
	begin
	    if(@currentServer.downcase==server.downcase&&
	       @currentChnl.downcase==channel.downcase)
		ret=true
	    end
	rescue NameError
	    ret=false
	end

	return ret
    end

    def setActiveBuffer(server,channel,noselect=false)
	@currentServer=server.to_s
	@currentChnl=channel.to_s

	@currentLog.setActiveBuffer(@currentServer,@currentChnl)
	
	unless(noselect)
	    if(@currentChnl.empty?)
		@tree.selectSingleElement(@currentServer)
	    else
		@tree.selectSingleElement(@currentServer,@currentChnl)
	    end
	end
	
	@buffer.setWindowTitle(channel.to_s+"@"+server.to_s)
    end

    def notify_signal(obj,signal,*args)
	if(obj==@tree)
	    case signal
	    when 'select'
		self.setActiveBuffer(args[0].to_s,args[1].to_s,true)
	    end
	end
    end

    def write(msg)
	unless(@currentLog.write(msg))
	    @otherLog.appendLine(msg)
	end
    end

    def default_action(msg)
	@tree.push(msg)
	self.write(msg)
    end

    def on_link_established(msg)
	@tree.push(msg)

	@currentServer=msg.server
	@currentChnl=""
	self.setActiveBuffer(msg.server,"")
    end

    def on_link_closed(msg)
	@tree.push(msg)

	@currentServer=nil
	@currentChnl=nil
	self.setActiveBuffer("","")
    end

    def on_recv_cmnd_quit(msg)
	if(msg.isSelfMessage?)
	    @tree.push(msg)

	    @currentServer=nil
	    @currentChnl=nil
	    self.setActiveBuffer("","")
	else
	    self.default_action(msg)
	end
    end

    def on_recv_cmnd_join(msg)
	self.default_action(msg)
	if(msg.isSelfMessage?)
	    self.setActiveBuffer(msg.server,msg.args[0])
	end
    end

    def on_recv_cmnd_part(msg)
	self.default_action(msg)
	if(msg.isSelfMessage?)
	    @currentChnl=""
	    self.setActiveBuffer(msg.server,"")
	end
    end

    def on_recv_cmnd_kick(msg)
	self.default_action(msg)
	if(msg.to==msg.selfNick)
	    @currentChnl=""
	    self.setActiveBuffer(msg.server,"")
	end
    end

    def on_recv_cmnd_ping(msg)
	# NOP
    end
    alias on_recv_cmnd_pong on_recv_cmnd_ping
end


class MainWindow<LogHolder::Logger
    def initialize
	super(LogBuffer)

	@currentServer=nil
	@currentChnl=nil

	setWindow
    end

    attr_reader :window
    attr_reader :menu_bar
    attr_reader :body
    attr_reader :statusbar
    attr_reader :rootbox

    def getCurrentServer
	return @body.currentServer
    end

    def getCurrentChannel
	return @body.currentChnl
    end

    def setWindowTitle(str)
	@window.set_title(ERICA_DEFAULT_TITLE+": "+str.to_s)
    end

    def exit
	begin
	    self.closeAll
	rescue
	end
	Gtk.main_quit
    end

    def dispatch(msg)
	msg=super
	if(msg.instance_of?(Rica::Message))
	    @body.dispatch(msg)
	end
    end

    private
    def setWindow
	@window=Gtk::Window.new(Gtk::WINDOW_TOPLEVEL)
	@window.set_title(ERICA_DEFAULT_TITLE)
	@window.set_default_size(ERICA_DEFAULT_WIDTH,
				 ERICA_DEFAULT_HEIGHT)

	setSignals
	layout
	@window.show
    end

    def setSignals
	@window.signal_connect('destroy'){
	    Gtk.main_quit
	}
    end

    def layout
	@rootbox=Gtk::VBox.new(false,0)
	
	@menubar=setmenu
	@menubar.show
	
	@body=BuffersControler.new(self)
	@body.tree.set_usize(ERICA_DEFAULT_TREE_WIDTH,
				  ERICA_DEFAULT_TREE_HEIGHT)
	@body.currentLog.set_usize(ERICA_DEFAULT_CLOG_WIDTH,
					ERICA_DEFAULT_CLOG_HEIGHT)

	@statusbar=Gtk::Statusbar.new
	@statusbar.show
	
	@rootbox.pack_start(@menubar,false,false,0)
	@rootbox.pack_start(@body,true,true,0)
	@rootbox.pack_start(@statusbar,false,false,0)
	
	@rootbox.show
	@window.add(rootbox)
    end

    def setmenu
	menubar=Gtk::MenuBar.new
	
	menu_file=Gtk::MenuItem.new('File')
	menu_file.show
	menubar.append(menu_file)

	return menubar
    end
end

connectiondiag=Rica::ConnectionDiag.new
ctcp=Rica::CtcpResponder.new
ctcp.version="Erica 0.2 with "+ctcp.version
window=MainWindow.new
Gtk.main
