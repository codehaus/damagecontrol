require 'damagecontrol/util/Logging'
require 'damagecontrol/util/FileUtils'

module DamageControl
  class AbstractSCM
    include FileUtils
    include Logging
    
    public
    
      attr_reader :checkout_dir
      attr_reader :config_map
  
      def working_dir
        checkout_dir
      end    
      
    protected

    def initialize(config_map)
      @config_map = config_map

      checkout_dir = config_map["checkout_dir"] || required_config_param("checkout_dir")
      @checkout_dir = to_os_path(File.expand_path(checkout_dir)) unless checkout_dir.nil?
    end

    def required_config_param(param)
      raise "required configuration parameter: #{param}"
    end
      
    def trigger_script_name
      "dctrigger.rb"
    end
    
    def trigger_script
%{require 'xmlrpc/client'

url = ARGV[0]
project_name = ARGV[1]

puts "Trigging build of \#{project_name} DamageControl on \#{url}"
client = XMLRPC::Client.new2(url)
build = client.proxy("build")
result = build.trig(project_name, Time.now.utc.strftime("%Y%m%d%H%M%S"))
puts result
}
    end
    
    def ruby_path
      if(windows?)
        "ruby"
      else
        "/home/services/dcontrol/ruby/bin/ruby"
        "ruby"
      end
    end

    # Works with ViewCVS (which works with CVS and SVN) and Fisheye (works with CVS and soon SVN)
    def view_cvs_url_to_change(change)
      view_cvs_url = config_map["view_cvs_url"]
      return "root/#{config_map['project_name']}/checkout/#{mod}/#{change.path}" if view_cvs_url.nil? || view_cvs_url == "" 
      
      view_cvs_url_patched = "#{view_cvs_url}/" if(view_cvs_url && view_cvs_url[-1..-1] != "/")
      url = "#{view_cvs_url_patched}#{change.path}"
      url << "?r1=#{change.revision}&r2=#{change.previous_revision}" if(change.previous_revision)
      url
    end
  end
end