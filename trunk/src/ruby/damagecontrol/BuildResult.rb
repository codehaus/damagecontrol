require 'damagecontrol/FileSystem'
require 'damagecontrol/scm/DefaultSCMRegistry'

module DamageControl
  class BuildResult
    # these should be set before exceution
    attr_reader :project_name, :scm, :scm_path, :build_command_line, :build_command_relative_dir
    
    # these should be set after execution
    attr_accessor :label, :timestamp, :error_message, :successful

    def initialize(
      project_name=nil, \
      scm=DefaultSCMRegistry.new, \
      scm_path=nil, \
      global_checkout_root_dir=nil, \
      build_command_line=nil, \
      build_command_relative_dir=".", \
      filesystem=FileSystem.new \
    )
      @project_name = project_name
      @scm = scm
      @scm_path = scm_path
      @global_checkout_root_dir = global_checkout_root_dir
      @build_command_line = build_command_line
      @build_command_relative_dir = build_command_relative_dir
      @filesystem = filesystem
    end
    
    def execute(&proc)
      @scm.checkout(scm_path, checkout_dir, &proc)
      do_build(&proc)
    end

  private
  
    def do_build
      @filesystem.chdir("#{checkout_dir}/#{@build_command_relative_dir}")
      IO.popen(build_command_line) do |output|
        output.each_line do |line|
          yield line
        end
      end
    end

    def checkout_dir
      "#{@global_checkout_root_dir}/#{project_name}/#{branch}"
    end
    
    def branch
      "MAIN"
    end
  end
end