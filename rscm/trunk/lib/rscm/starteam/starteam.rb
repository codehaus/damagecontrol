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
  # The RSCM StarTeam class requires that the following software be installed:
  #
  # * Java Runtime (1.4.2)
  # * StarTeam SDK
  # * Apache Ant (http://ant.apache.org/)
  #
  class StarTeam < AbstractSCM

    attr_accessor :st_user_name, :st_password, :st_server_name, :st_server_port, :st_project_name, :st_view_name, :st_folder_name

    def initialize(st_user_name=nil, st_password=nil, st_server_name=nil, st_server_port=nil, st_project_name=nil, st_view_name=nil, st_folder_name=nil)
      @st_user_name, @st_password, @st_server_name, @st_server_port, @st_project_name, @st_view_name, @st_folder_name = st_user_name, st_password, st_server_name, st_server_port, st_project_name, st_view_name, st_folder_name
    end

    def changesets(checkout_dir, from_identifier=Time.epoch, to_identifier=Time.infinity, files=nil)
      # just assuming it is a Time for now, may support labels later.
      # the java class really wants rfc822 and not rfc2822, but this works ok anyway.
      from = from_identifier.to_rfc2822
      to = to_identifier.to_rfc2822      

      changesets = java("getChangeSets(\"#{from}\";\"#{to}\")")
      raise "changesets must be of type #{ChangeSets.name} - was #{changesets.class.name}" unless changesets.is_a?(::RSCM::ChangeSets)

      # Just a little sanity check
      if(changesets.latest)
        latest_time = changesets.latest.time
        if(latest_time < from_identifier || to_identifier < latest_time)
          raise "Latest time (#{latest_time}) is not within #{from_identifier}-#{to_identifier}"
        end
      end
      changesets
    end

    def checkout(checkout_dir)
      files = java("checkout(\"#{checkout_dir}\")")
      files
    end
    
  private
  
    def cmd
      rscm_jar = File.expand_path(File.dirname(__FILE__) + "../../../../ext/rscm.jar")
      starteam_jars = Dir["#{ENV['RSCM_STARTEAM']}/Lib/*jar"].join(File::PATH_SEPARATOR)
      ant_jars = Dir["#{ENV['ANT_HOME']}/lib/*jar"].join(File::PATH_SEPARATOR)
      classpath = "#{rscm_jar}#{File::PATH_SEPARATOR}#{ant_jars}#{File::PATH_SEPARATOR}#{starteam_jars}"

      "java -Djava.library.path=\"#{ENV['RSCM_STARTEAM']}#{File::SEPARATOR}Lib\" -classpath \"#{classpath}\" org.rubyforge.rscm.Main"
    end

    def java(m)
      raise "The RSCM_STARTEAM environment variable must be defined and point to the StarTeam SDK directory" unless ENV['RSCM_STARTEAM']
      raise "The ANT_HOME environment variable must be defined and point to the Ant installation directory" unless ENV['ANT_HOME']

      clazz = "org.rubyforge.rscm.starteam.StarTeam"
      ctor_args = "#{@st_user_name};#{@st_password};#{@st_server_name};#{@st_server_port};#{@st_project_name};#{@st_view_name};#{@st_folder_name}"

#     Uncomment if you're not Aslak - to run against a bogus java class.
#      clazz = "org.rubyforge.rscm.TestScm"
#      ctor_args = "hubba;bubba"

      command = "new #{clazz}(#{ctor_args}).#{m}"
      tf = Tempfile.new("rscm_starteam")
      tf.puts(command)
      tf.close 
      cmdline = "#{cmd} #{tf.path}"
#puts "------------"
#puts command
#puts "------------"
#puts cmdline
#puts "------------"
      IO.popen(cmdline) do |io|
#        io = io.read
#        puts io
#puts "------------"
        YAML::load(io)
      end
    end

  end
end
