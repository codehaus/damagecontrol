require "xmlrpc/client"

class Page
	attr_accessor :space, :content

	def initialize(result, server, token)
		@title = result["title"]
		@url = result["url"]
		@parent = result["parentId"]
		@id = result["id"]
		@space = result["space"]
		@locks = result["locks"]

		@token = token
		@server = server

		@page = nil

		@content = nil
	end

	def content
		if (!@content)
			@page = @server.call("confluence1.getPage", @token, @id)
			@content = @page["content"]
		end
		@content
	end

	def to_hash
		result = {
			"title" => @title,
			"content" => @content,
			"space" => @space
		}
		return result
	end
	
	def to_s
		@title
	end
end

class Space
	attr_reader :name, :homepage, :url, :description, :key
	def initialize(result, server, token)
		@result = result
		@server = server
		@token = token
		@name = @result["name"]
		@homepage = @result["homePage"]
		@url = @result["url"]
		@description = @result["description"]
		@key = @result["key"]
	end

	def []
		pages = []
		@server.call("confluence1.getPages", @token, @key).each{ |page|
			pages << Page.new(page, @server, @token)
		}
		return pages
	end

	def to_s
		@key
	end

	def store(page)
		puts "store"
		page.space = @key

		#puts page.to_hash
		@server.call("confluence1.storePage", @token, page.to_hash)
	end
end

class Confluence

	def initialize(host, username, password)
		@server = XMLRPC::Client.new(host,"/rpc/xmlrpc")
		@token =  @server.call("confluence1.login", username, password)
	end


	def space(space)
		Space.new(@server.call("confluence1.getSpace", @token, space), @server, @token)
	end


	def []
		spaces = []
		@server.call("confluence1.getSpaces", @token).each { |space|
			spaces << Space.new(space, @server, @token)
		}
		return spaces
	end

	def newPage(title, content)
		result = {"title"=>title}
		page = Page.new(result, @server, @token)
		page.content = content
		return page
	end
end

confluence = Confluence.new("docs.codehaus.org","lars3loff","lars3loff")
#puts confluence[]
#confluence.space("DAMAGECONTROL")[].each { |page|
#	puts page
#	puts page.content
#}

dummy = confluence.newPage("DummyPage","Dummy Content Dummy Dummy")
confluence.space("DAMAGECONTROL").store(dummy)
