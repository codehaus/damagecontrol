module DamageControl
  class BuildResult
    # these should be set before exceution
    attr_accessor :build_command_line, :scm_path
    
    # these should be set after execution
    attr_accessor :project_name, :label, :timestamp, :error_message, :successful
  end
end