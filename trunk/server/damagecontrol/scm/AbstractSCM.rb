require 'damagecontrol/util/Logging'
require 'damagecontrol/util/FileUtils'

module DamageControl
  class AbstractSCM
    include FileUtils
    include Logging
    
    attr_reader :checkout_dir

  protected

    attr_reader :config_map

    def initialize(config_map)
      @config_map = config_map

      checkout_dir = config_map["checkout_dir"] || required_config_param("checkout_dir")
      @checkout_dir = to_os_path(File.expand_path(checkout_dir)) unless checkout_dir.nil?
    end

    def required_config_param(param)
      raise "required configuration parameter: #{param}"
    end
      
  end
end