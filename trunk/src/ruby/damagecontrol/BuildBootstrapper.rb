require 'damagecontrol/BuildResult'

module DamageControl

  class BuildBootstrapper

    # creates a trigger command
    #
    # @param project_name a human readable name for the module
    # @param path full SCM spec (example: :local:/cvsroot/picocontainer:pico)
    # @param build_command_line command line that will run the build
    # @param relative_path relative path in dc's checkout where build
    #        command will be executed from
    # @param host where the dc server is running
    # @param port where the dc server is listening
    # @param replace_string what to replace "/" with (needed for CVS on windows)
    def trigger_command(project_name, spec, build_command_line, relative_path, nc_command, dc_host, dc_port, replace_string="/")
      "echo #{project_name},#{spec.gsub('/', replace_string)},#{build_command_line},#{relative_path}|#{nc_command} #{dc_host} #{dc_port}"
    end

    def bootstrap_build(build_spec, root_dir)
      project_name, scm_spec, build_command_line, build_path = build_spec.split(",")
      BuildResult.new(project_name.chomp, scm_spec.chomp, build_command_line.chomp, build_path.chomp, root_dir.chomp)
    end

  end
end