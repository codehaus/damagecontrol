require 'yaml'

require 'damagecontrol/Build'

module DamageControl

  class BuildBootstrapper
    def create_build(build_yaml)
      yaml_doc = YAML::load(build_yaml)
      Build.new(yaml_doc["project_name"], yaml_doc)
    end

    def BuildBootstrapper.conf_file(project_name)
      "damagecontrol-#{project_name}.conf"
    end

    # Creates a trigger command that is compatible with the create_build
    # method. This method is used to create a command string that can
    # be installed in various SCM's trigger mechanisms.
    #
    # @param project_name a logical name for the project (no spaces please)
    # @param host where the dc server is running
    # @param port where the dc server is listening
    # @param replace_string what to replace "/" with (needed for CVS on windows)
    def BuildBootstrapper.trigger_command(project_name, nc_command, dc_host, dc_port, path_sep="/")
      "cat #{conf_file}|#{nc_command} #{dc_host} #{dc_port}"
    end

    def BuildBootstrapper.build_spec(project_name, spec, build_command_line, nag_email, nc_command, dc_host, dc_port, path_sep="/")
      {
        "project_name" => project_name,
        "scm_spec" => spec.gsub('/', path_sep),
        "build_command_line" => build_command_line,
        "nag_email" => nag_email
      }.to_yaml
    end
end

end