require 'yaml'

require 'damagecontrol/core/Build'

# DEPRECATED DEPRECATED DEPRECATED DEPRECATED DEPRECATED DEPRECATED DEPRECATED 
# DEPRECATED DEPRECATED DEPRECATED DEPRECATED DEPRECATED DEPRECATED DEPRECATED 
# DEPRECATED DEPRECATED DEPRECATED DEPRECATED DEPRECATED DEPRECATED DEPRECATED 
# this functionality has been moved to the scm implementations and to ProjectConfigurationRepository

module DamageControl

  class BuildBootstrapper
    def create_build(build_yaml)
      eof_stripped = ""
      build_yaml.each { |line|
        if(line.chomp == "...")
          break
        else
          # Workaround for new Ruby symbol semantics in YAML.
          # A String that starts with a colon will be converted
          # to a symbol, which is not what we want.
          # Therefore, replace the offending ":"s with "_" and take it out afterwards.
          line.gsub!(/:pserver:/, "_pserver:")
          line.gsub!(/:local:/, "_local:")
          line.gsub!(/:ext:/, "_ext:")

          eof_stripped << line
        end
      }
      map = YAML::load(eof_stripped)
      map.each{ |key, value|
        value.gsub!(/_pserver:/, ":pserver:")
        value.gsub!(/_local:/, ":local:")
        value.gsub!(/_ext:/, ":ext:")
      }
      
      Build.new(map["project_name"], Time.now, map)
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
    def BuildBootstrapper.trigger_command(project_name, conf_file, nc_command, dc_host, dc_port)
      "#{nc_command} #{dc_host} #{dc_port} < #{conf_file}"
    end

    def BuildBootstrapper.build_spec(project_name, scm_spec, build_command_line, nag_email, path_sep="/")
      {
        "project_name" => project_name,
        "scm_spec" => scm_spec.gsub('/', path_sep),
        "build_command_line" => build_command_line,
        "nag_email" => nag_email
      }.to_yaml << "\n...\n"
    end
end

end