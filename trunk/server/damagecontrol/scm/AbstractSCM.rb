require 'damagecontrol/util/Logging'
require 'damagecontrol/util/FileUtils'

module DamageControl
  class AbstractSCM
    include FileUtils
    include Logging
    
    protected
    
      attr_reader :config_map
      attr_reader :working_dir_root
      
      def initialize(config_map)
        @config_map = config_map
        
        working_dir_root = config_map["working_dir_root"] || required_config_param("working_dir_root")
        @working_dir_root = to_os_path(File.expand_path(working_dir_root)) unless working_dir_root.nil?
      end
      
      def required_config_param(param)
        raise "required configuration parameter: #{param}"
      end
      
  end
end