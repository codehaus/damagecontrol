module Pebbles
  class MVCServlet
    attr_accessor :templatedir
    
    def initialize
      self.templatedir = "."
    end
    
    def get_instance(config, *options)
      self
    end
    
    def service(req, res)
      Thread.current["request"] = req
      Thread.current["response"] = res
      command = req.query['command'] || "default_command"
      
      begin
        self.send(command) 
      rescue Exception => e
        response.body = "<html><body><pre>" + e.message + "\n" + e.backtrace.join("\n") + "</pre></body></html>" 
      end
    end
    
    def request
      Thread.current["request"]
    end
    
    def response
      Thread.current["response"]
    end
    
    def erb(template, binding)
      response["Content-Type"] = "text/html"
      puts templatedir
      template = File.new("#{templatedir}/#{template}").read
      response.body=ERB.new(template).result(binding)
    end
  end
end