require 'yaml'

module DamageControl
  module Process
    # Wrapper around standard bootstrapper for WEBrick/lightyypd
    class Server < Base
      def init
      end
      
      def run
        require File.expand_path(File.join(File.dirname(__FILE__),
           "..", "..", "..", "config", "dc_environment"))
        config_file = "#{DC_DATA_DIR}/dc.yml"
        unless File.exist?(config_file)
          require 'fileutils'
          source = File.expand_path(File.join(File.dirname(__FILE__),
             "..", "..", "..", "config", "dc.yml"))
          puts "=> #{config_file} not found, copying from #{source}"
          FileUtils.cp source, config_file
        end        
        
        config = YAML::load_file(config_file)
        server = config.delete('server') || ''
        args = config.to_a.collect{|kv| "--#{kv[0]} #{kv[1]}"}.join(" ")
        
        script = File.expand_path(File.join(File.dirname(__FILE__),
           "..", "..", "..", "script", "server"))
        exec "ruby #{script} #{server} #{args} --environment #{ENV['RAILS_ENV']}"
      end
    end
  end
end