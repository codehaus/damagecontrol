require 'damagecontrol/FileSystem'
require 'damagecontrol/scm/DefaultSCMRegistry'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/ant/ant'

module DamageControl

  class Modification
    attr_accessor :developer
    attr_accessor :path
    attr_accessor :message
    attr_accessor :time
  end

  class Build

    # these should ideally be set before exceution
    # they are exposed as accessors only so they can be re-set from a cc log file
    # we should turn them into proper get/set methods so that we can perform
    # checking if a non-nil value is overwritten with a different value
    attr_accessor :project_name, :scm_spec, :build_command_line, :scm
    
    # these should be set after execution
    attr_accessor :label
    attr_accessor :timestamp
    attr_accessor :error_message
    attr_accessor :successful
    attr_accessor :modification_set
    attr_accessor :filesystem

    def initialize(
      project_name              = nil , \
      scm_spec                  = nil , \
      build_command_line        = nil , \
      global_checkout_root_dir  = nil , \
      scm                       = DefaultSCMRegistry.new)

      @filesystem                = FileSystem.new
      @project_name             = project_name
      @scm_spec = scm_spec
      @build_command_line = build_command_line
      @global_checkout_root_dir = global_checkout_root_dir
      @filesystem = filesystem
      @scm = scm
      
      @modification_set = []
      
      @label                    = Time.now.to_i.to_s
    end
    
    def checkout
      @scm.checkout(scm_spec, absolute_checkout_path, &proc)
    end

    def execute(&proc)
      puts "Changing dir to #{absolute_checkout_path}"
      @filesystem.chdir(absolute_checkout_path)
      IO.popen(build_command_line) do |output|
        output.each_line do |line|
          yield line
        end
      end
    end
 
    def absolute_checkout_path
      "#{@global_checkout_root_dir}/#{branch_path}/checkout"
    end

    def reports_path
      "#{branch_path}/reports"
    end
    
    def absolute_reports_path
      "#{@global_checkout_root_dir}/#{reports_path}"
    end

    def logs_path
      "#{branch_path}/logs"
    end

    def log_file_path
      "#{branch_path}/#{label}.log"
    end
    
    def absolute_log_file_path
      "#{@global_checkout_root_dir}/#{log_file_path}"
    end

    def branch_path
#      "#{@global_checkout_root_dir}/#{project_name}/#{@scm.mod(scm_spec)}/#{@scm.branch(scm_spec)}"
      "#{project_name}/#{@scm.mod(scm_spec)}/#{@scm.branch(scm_spec)}"
    end
  end
end