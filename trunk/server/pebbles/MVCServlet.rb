require 'erb'
require 'uri'
require 'pebbles/RiteMesh'

module Pebbles
  class SimpleServlet
    def get_instance(config, *options)
      self
    end
    
    def service(req, res)
      Thread.current["request"] = req
      Thread.current["response"] = res

      response["Content-Type"] = content_type
    end
    
  protected
    
    def required_parameter(parameter)
      raise WEBrick::HTTPStatus::BadRequest, "parameter required `#{parameter}'."
    end
    
    def html_quote(text)
      text.gsub(/</, "&lt;")
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
    
    def content_type
      "text/html"
    end
    
  end

  class MVCServlet < SimpleServlet
    
    include RiteMesh
    
    def service(req, res)
      super(req, res)

      # http://lab.artlung.com/other/anti-cache/
#      response["CacheControl"] = "no-cache"
      response["Pragma"] = "no-cache"
      response["Expires"] = "-1"
      
      action = req.query['action'] || "default_action"
      
      begin
        raise "no such action: #{action}" unless actions.index(action)
        self.send(action.untaint)
      rescue Exception => e
        response.body = "<html><body><pre>" + e.class.name + ": " + e.message + "\n" + e.backtrace.join("\n\t") + "</pre></body></html>" 
      end
    end
    
    def actions
      self.public_methods - self.class.superclass.public_instance_methods
    end
    
    def send(method, *args)
      raise SecurityError, "Insecure operatiton: #{method}" if method.tainted? || args.tainted?
      super(method, *args)
    end
    
    def action_redirect(action_name, params)
      params_enc = params.collect {|key, value| "#{key}=#{value}" }.join("&")
      redirect("#{request.path}?action_name=#{action_name}&#{params_enc}")
    end
        
    def erb(template, binding)
      raise "The constructor of #{self.class.name} should do: @template_dir = File.expand_path(File.dirname(__FILE__))" unless @template_dir
      template_path = File.expand_path("#{template_dir}/#{template}")
      template = File.new(template_path).read.untaint
      ERB.new(template).result(binding)
    end
    
    def render(erb_template, binding)
      response.body = erb(erb_template, binding)
      unless ritemesh_template.nil?
        ritemesh_template_content = File.new("#{template_dir}/#{ritemesh_template}").read.untaint
        response.body = mesh(response.body, ritemesh_template_content, binding)
      end
    end
    
#  protected
    attr_reader :template_dir
    
  
    def ritemesh_template
      # disabled by default
      nil
    end
  end
end
