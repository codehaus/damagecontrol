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

    attr_accessor :user_name, :password, :server_name, :server_port, :project_name, :view_name, :folder_name

    def initialize(user_name=nil, password=nil, server_name=nil, server_port=nil, project_name=nil, view_name=nil, folder_name=nil)
      @user_name, @password, @server_name, @server_port, @project_name, @view_name, @folder_name = user_name, password, server_name, server_port, project_name, view_name, folder_name
    end

    def name
      "StarTeam"
    end
    
    def form_file
      File.dirname(__FILE__) + "/form.html"
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
        latetime = changesets.latest.time
        if(latetime < from_identifier || to_identifier < latetime)
          raise "Latest time (#{latetime}) is not within #{from_identifier}-#{to_identifier}"
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
      ctor_args = "#{@user_name};#{@password};#{@server_name};#{@server_port};#{@project_name};#{@view_name};#{@folder_name}"

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
#        File.open("aslak.yml", "w") {|f| f.puts io}
#puts "------------"
        YAML::load(io)
      end
    end

  end
end
