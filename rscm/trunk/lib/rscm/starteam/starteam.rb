require 'fileutils'
require 'tempfile'
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
  # * Apache Ant (http://ant.apache.org/)
  #
  class StarTeam < AbstractSCM

    def initialize(user_name, password, server_name, server_port, project_name, view_name, folder_name)
      raise "The RSCM_STARTEAM environment variable must be defined and point to the StarTeam SDK directory" unless ENV['RSCM_STARTEAM']
      raise "The ANT_HOME environment variable must be defined and point to the Ant installation directory" unless ENV['ANT_HOME']

      clazz = "org.rubyforge.rscm.starteam.StarTeam"
      ctor_args = "#{user_name};#{password};#{server_name};#{server_port};#{project_name};#{view_name};#{folder_name}"

#     Uncomment if you're not Aslak - to run against a bogus java class.
      clazz = "org.rubyforge.rscm.TestScm"
      ctor_args = "hubba;bubba"

      @new_class = "new #{clazz}(#{ctor_args})"

      rscm_jar = File.expand_path(File.dirname(__FILE__) + "../../../../ext/rscm.jar")
      starteam_jars = Dir["#{ENV['RSCM_STARTEAM']}/Lib/*jar"].join(File::PATH_SEPARATOR)
      ant_jars = Dir["#{ENV['ANT_HOME']}/lib/*jar"].join(File::PATH_SEPARATOR)
      classpath = "#{rscm_jar}#{File::PATH_SEPARATOR}#{ant_jars}#{File::PATH_SEPARATOR}#{starteam_jars}"

      @cmd = "java -Djava.library.path=\"#{ENV['RSCM_STARTEAM']}#{File::SEPARATOR}Lib\" -classpath \"#{classpath}\" org.rubyforge.rscm.Main"
    end

    def changesets(checkout_dir, from_identifier, to_identifier=nil, files=nil)

      # just assuming it is a Time for now, may support labels later.
      # the java class really wants rfc822 and not rfc2822, but this works ok anyway.
      from = from_identifier.to_rfc2822
      to = to_identifier.to_rfc2822      

      java("getChangeSets(\"#{from}\";\"#{to}\")")
    end

    def checkout(checkout_dir, to_identifier=nil)
      to = to_identifier.to_rfc2822      

      java("checkout(\"#{checkout_dir}\";\"#{to}\")")
    end

    def java(m)
      command = "#{@new_class}.#{m}"
      tf = Tempfile.new("rscm_starteam")
      tf.puts(command)
      tf.close      
      IO.popen("#{@cmd} #{tf.path}") do |io|
#        io = io.read
#        puts io
        YAML::load(io)
      end
    end

  end
end
