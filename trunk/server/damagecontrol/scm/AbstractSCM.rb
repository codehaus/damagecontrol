require 'damagecontrol/util/Logging'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/scm/Changes'
require 'xmlrpc/utils'

module DamageControl
  class AbstractSCM
    include FileUtils
    include Logging
    include XMLRPC::Marshallable
    
  public

    attr_accessor :checkout_dir
    
    def working_dir
      checkout_dir
    end

    def can_install_trigger?
      false
    end

    def trigger_installed?(project_name)
      false
    end

    def can_create?
      false
    end

    def exists?
      true
    end

    def trigger_command(damagecontrol_install_dir, project_name, dc_url)
      script = "#{script_prefix}#{damagecontrol_install_dir}/bin/requestbuild#{script_suffix}"
      "#{to_os_path(script)} --url #{dc_url} --projectname #{project_name}"
    end

    def checkout(time = nil, &proc)
    end

    def changesets(from_time, to_time, &proc)
      ChangeSets.new
    end
    
    def checkout_dir=(checkout_dir)
      raise "checkout_dir can't be nil" unless checkout_dir
      checkout_dir = to_os_path(File.expand_path(checkout_dir))
      @checkout_dir = checkout_dir
    end
    
    def ==(other_scm)
      return false if self.class != other_scm.class
      self.instance_variables.each do |var|
        return false if self.instance_eval(var) != other_scm.instance_eval(var)
      end
      true
    end

  protected

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
