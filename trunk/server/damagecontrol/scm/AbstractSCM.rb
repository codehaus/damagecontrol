require 'damagecontrol/util/Logging'
require 'damagecontrol/util/FileUtils'

module DamageControl
  class AbstractSCM
    include FileUtils
    include Logging
    
    attr_reader :checkout_dir
    attr_reader :config_map

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

puts "Nudging DamageControl on \#{url} to build project \#{project_name}"
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
#        "ruby"
      end
    end
    
  end
end