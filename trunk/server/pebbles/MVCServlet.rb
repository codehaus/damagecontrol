require 'erb'
require 'uri'
require 'pebbles/RiteMesh'

module Pebbles
  class SimpleServlet

    FORWARDED_HOST_HEADER = "x-forwarded-host"

    def get_instance(config, *options)
      self
    end
    
    def html_quote(text)
      text.gsub(/</, "&lt;")
    end

    def to_uri(uri)
      if uri.is_a?(URI) then uri else URI.parse(uri) end
    end

    def protocol
      request.meta_vars["SERVER_PROTOCOL"].split(/\//)[0].downcase
    end
    
    def host
      host = request.host
      host = request.header[FORWARDED_HOST_HEADER].to_s unless request.header[FORWARDED_HOST_HEADER].nil?
    end

    def redirect(url)
      #dump_headers
      uri = to_uri(url)
      if uri.host.nil?
        puts "adding host #{host}"
        uri = to_uri("#{protocol}://#{host}#{uri}")
        puts "result #{uri}"
      end
      response["Location"] = uri.to_s
      response.status = WEBrick::HTTPStatus::Found.code
    end

    def dump_headers
      puts "================ dump_headers"
      puts "request:"
      p request
      puts "header:"
      p request.header
      puts "meta:"
      p request.meta_vars
      puts "==============="
    end
    
  end

  class MVCServlet < SimpleServlet
    attr_reader :templatedir
    
    include RiteMesh
    
    def templatedir
      "."
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
        
    def request
      Thread.current["request"]
    end
    
    def response
      Thread.current["response"]
    end
    
    def erb(template, binding)
      template = File.new("#{templatedir}/#{template}").read.untaint
      ERB.new(template).result(binding)
    end
    
    def render(erb_template, binding)
      response.body = erb(erb_template, binding)
      unless ritemesh_template.nil?
        ritemesh_template_content = File.new("#{templatedir}/#{ritemesh_template}").read.untaint
        response.body = mesh(response.body, ritemesh_template_content, binding)
      end
    end
    
    protected
    
    def ritemesh_template
      # disabled by default
      nil
    end
  end
end
