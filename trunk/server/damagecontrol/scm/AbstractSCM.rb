require 'damagecontrol/util/Logging'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/scm/Changes'

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

    def can_install_trigger?
      false
    end

    def trigger_command(damagecontrol_install_dir, project_name, dc_url)
      script = "#{script_prefix}#{damagecontrol_install_dir}/bin/requestbuild#{script_suffix}"
      "#{to_os_path(script)} --url #{dc_url} --projectname #{project_name}"
    end

    def web_url_to_change(change)
      "root/#{config_map['project_name']}/#{working_dir}/#{change.path}"
    end
    
    def checkout(time = nil, &proc)
    end

    def changesets(from_time, to_time, &proc)
      ChangeSets.new
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

    def script_prefix
      if windows? then "" else "sh " end
    end

    def script_suffix
      if windows? then ".cmd" else "" end
    end
      
    def cmd(dir, cmd, &proc)
      if block_given? then yield "#{cmd}\n" else logger.debug("#{cmd}\n") end
      cmd_with_io(dir, cmd) do |io|
        io.each_line do |progress|
          if block_given? then yield progress else logger.debug(progress) end
        end
      end
    end
    
  end
end
