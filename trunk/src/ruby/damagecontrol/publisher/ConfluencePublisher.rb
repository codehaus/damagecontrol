require 'damagecontrol/AsyncComponent'
require "xmlrpc/client"

# Authors: Zohar Melamed, Aslak Hellesoy
#
module DamageControl

  class ConfluencePublisher < AsyncComponent
  
    def initialize(url, user, password)
      @user = user
      @password = password
      @confluence = XMLRPC::Client.new(url, "/rpc/xmlrpc", 80)
    end
    
    def post(space_name, parent_page_name, title,  content)
      begin
        token = @confluence.call("confluence1.login", @user, @password)
        page = {"space" => space_name, "content" => content, "title" => title}
        @confluence.call("confluence1.storePage", token, page)
      rescue XMLRPC::FaultException => e
        puts "Error:"
        puts e.faultCode
        puts e.faultString
      end
    end
  
  end

end
