require 'fileutils'
require 'rscm/changes'
require 'rscm/abstract_scm'
require 'yaml'

class Time
  def to_rfc2822
    utc.strftime("%a, %d %b %Y %H:%M:%S +0000")
  end
end

module RSCM
  # WARNING! THE STARTEAM IMPLEMENTATION IS INCOMPLETE AT THIS STAGE.
  # VOLUNTEERS TO COMPLETE IT ARE WELCOME.
  #
  # The RSCM StarTeam class requires that the following software be installed:
  #
  # * Java Runtime (1.4.2)
  # * StarTeam SDK
  #
  class StarTeam < AbstractSCM

    def initialize(user_name, password, server_name, server_port, project_name, view_name, folder_name)
      raise "The RSCM_STARTEAM environment variable must be defined and point to the StarTeam SDK directory" unless ENV['RSCM_STARTEAM']

      @user_name, @password, @server_name, @server_port, @project_name, @view_name, @folder_name = 
        user_name, password, server_name, server_port, project_name, view_name, folder_name
    end

    def changesets(checkout_dir, from_identifier, to_identifier=nil, files=nil)

      # just assuming it is a Time for now, may support labels later.
      # the java class really wants rfc822 and not rfc2822, but this works ok anyway.
      from = from_identifier.to_rfc2822
      to = to_identifier.to_rfc2822

      clazz = "org.rubyforge.rscm.TestScm"
      ctor_args = "huba luba"

#      clazz = "org.rubyforge.rscm.starteam.StarTeam"
#      ctor_args = "#{@user_name} #{@password} #{@server_name} #{@server_port} #{@project_name} #{@view_name} #{@folder_name}"

      rscm_jar = File.expand_path(File.dirname(__FILE__) + "../../../../ext/rscm.jar")
      starteam_jars = Dir["#{ENV['RSCM_STARTEAM']}/Lib/*jar"].join(File::PATH_SEPARATOR)
      classpath = "#{rscm_jar}#{File::PATH_SEPARATOR}#{starteam_jars}"
      cmd = "java -Djava.library.path=\"#{ENV['RSCM_STARTEAM']}#{File::SEPARATOR}Lib\" -classpath \"#{classpath}\" org.rubyforge.rscm.Main \"#{from}\" \"#{to}\" . #{clazz} #{ctor_args}"
      IO.popen(cmd) do |io|
        YAML::load(io)
      end
    end
  end
end
