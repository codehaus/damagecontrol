module Pebbles
  class MVCServlet
    attr_accessor :templatedir
    
    def initialize
      self.templatedir = "."
    end
    
    def get_instance(config, *options)
      self
    end
    
    def content_type
      "text/html"
    end
    
    def actions
      self.public_methods - self.class.superclass.public_instance_methods
    end
    
    def send(method, *args)
      raise SecurityError, "Insecure operatiton: #{method}" if method.tainted? || args.tainted?
      super(method, *args)
    end
    
    def service(req, res)
      Thread.current["request"] = req
      Thread.current["response"] = res
      action = req.query['action'] || "default_action"
      
      response["Content-Type"] = content_type
      
      begin
        raise "no such action: #{action}" unless actions.index(action)
        self.send(action.untaint)
      rescue Exception => e
        response.body = "<html><body><pre>" + e.class.name + ": " + e.message + "\n" + e.backtrace.join("\n\t") + "</pre></body></html>" 
      end
    end
    
    def action_redirect(action_name, params)
      params_enc = params.collect {|key, value| "#{key}=#{value}" }.join("&")
      redirect("#{request.path}?action_name=#{action_name}&#{params_enc}")
    end
    
    def redirect(url)
      response["Location"] = url
      response.status = WEBrick::HTTPStatus::Found.code
    end
    
    def request
      Thread.current["request"]
    end
    
    def response
      Thread.current["response"]
    end
    
    def erb(template, binding)
      response["Content-Type"] = "text/html"
      template = ""
      File.open("#{templatedir}/#{template}") do |io|
        template = io.read.untaint
      end
      response.body = ERB.new(template).result(binding)
    end
  end
end