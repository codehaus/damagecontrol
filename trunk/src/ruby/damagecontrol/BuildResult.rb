require 'damagecontrol/FileSystem'
require 'damagecontrol/scm/DefaultSCMRegistry'
require 'damagecontrol/ant/ant'

module DamageControl

  class BuildResult

    include Ant

    # these should ideally be set before exceution
    # they are exposed as accessors only so they can be re-set from a cc log file
    # we should turn them into proper get/set methods so that we can perform
    # checking if a non-nil value is overwritten with a different value
    attr_accessor :project_name, :scm_spec, :build_command_line, :build_path, :scm
    
    # these should be set after execution
    attr_accessor :label, :timestamp, :error_message, :successful, :developers, :modification

    def initialize(
      project_name              = nil , \
      scm_spec                  = nil , \
      build_command_line        = nil , \
      build_path                = nil , \
      global_checkout_root_dir  = nil , \
      filesystem                = FileSystem.new , \
      scm                       = DefaultSCMRegistry.new)

      @project_name             = project_name
      @scm_spec                 = scm_spec
      @build_command_line       = build_command_line
      @build_path               = build_path
      @global_checkout_root_dir = global_checkout_root_dir
      @filesystem               = filesystem
      @scm                      = scm
    end
    
    def execute(&proc)
      @scm.checkout(scm_spec, checkout_dir, &proc)
      do_build(&proc)
    end

    def absolute_build_path
      "#{checkout_dir}/#{@scm.mod(scm_spec)}/#{@build_path}"
    end

    def checkout_dir
      "#{@global_checkout_root_dir}/#{project_name}/#{@scm.mod(scm_spec)}/#{branch}"
    end
    
    def branch
      "MAIN"
    end

  private
  
    def do_build
      puts "Changing dir to #{absolute_build_path}"
      @filesystem.chdir("#{absolute_build_path}")
      cmdline = translate_command_to_ruby(build_command_line)
      puts "Executing build command line #{cmdline}"
      IO.popen(cmdline) do |output|
        output.each_line do |line|
          yield line
        end
      end
    end
    
    def translate_command_to_ruby(build_command_line)
      ant_commandline
    end
  end
end