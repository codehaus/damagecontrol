module DamageControl
  class BuildResult
    # these should be set before exceution
    attr_accessor :project_name, :build_command_line, :scm_path
    
    # these should be set after execution
    attr_accessor :label, :timestamp, :error_message, :successful
  end
end