require 'erb'
require 'uri'
require 'webrick/htmlutils'
require 'pebbles/RiteMesh'

module Pebbles
  module HTMLQuoting
    def html_quote(text)
      return "" unless text
      WEBrick::HTMLUtils.escape(text).gsub(/</, "&lt;").gsub(/>/, "&gt;").gsub(/\r?\n/, "<br/>")
    end
  end

  module SimpleERB
    protected
    
    # save the absolute path to the template directory
    # DamageControl is playing around with the working dir quite a bit because there's yet no fork implementation on Win32
    # usually __FILE__ is relative so it makes the web gui completely borked
    def absolute_template_dir
      @absolute_template_dir = File.expand_path(template_dir) unless defined?(@absolute_template_dir)
      @absolute_template_dir
    end
    
    def file_content(file)
      template_path = File.expand_path("#{absolute_template_dir}/#{file}")
      template = File.new(template_path).read.untaint
    end
    
    def erb(template, binding)
      begin
        ERB.new(file_content(template)).result(binding)
      rescue Exception
        ERB.new(file_content(error_page(template))).result(binding)
      end
    end
    
    # default template for error pages
    def error_page(template)
      'error.erb'
    end
    
    def template_dir
      raise "you must overload template dir"
    end
  end

  class SimpleServlet
    include SimpleERB
  
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
    include HTMLQuoting
    
    def cacheable?
      false
    end

    def service(request, response)
      super(request, response)

      # http://lab.artlung.com/other/anti-cache/
      if(request.query["auto_refresh"] != "true" and !cacheable?)
        # we _do_ want the browser to cache when auto_refresh is enabled, to avoid flickering of images
        response["Cache-control"] = "no-cache"
        response["Pragma"] = "no-cache"
        response["Expires"] = "-1"
      end

      def cacheable?
        false
      end
      
      action = request.query['action'] || "default_action"
      
      begin
        raise "no such action: #{action} in #{self.class.name}. Available:<br> #{actions.join('<br>')}" unless actions.index(action)
        self.send(action.untaint)
      rescue Exception => e
        response.body = "<html><body><pre>" + e.class.name + ": " + e.message + "\n" + e.backtrace.join("\n\t") + "</pre></body></html>" 
      end
    end
    
    def actions
      self.public_methods # - self.class.superclass.public_instance_methods
    end
    
    def send(method, *args)
      raise SecurityError, "Insecure operatiton: #{method}" if method.tainted? || args.tainted?
      super(method, *args)
    end
    
    def action_redirect(action_name, params={})
      params_enc = ""
      params_enc = "&" + params.collect {|key, value| "#{key}=#{value}" }.join("&") unless params.empty?
      redirect("#{request.path}?action_name=#{action_name}#{params_enc}")
    end
        
    def render(erb_template, binding)
      response.body = erb(erb_template, binding)
      unless ritemesh_template.nil?
        ritemesh_template_content = File.new("#{absolute_template_dir}/#{ritemesh_template}").read.untaint
        response.body = mesh(response.body, ritemesh_template_content, binding)
      end
    end
    
    def ritemesh_template
      # disabled by default
      nil
    end
  end
end
