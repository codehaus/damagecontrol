require 'damagecontrol/scm/SCM'
require 'damagecontrol/FileUtils'
require 'damagecontrol/BuildBootstrapper'

module DamageControl

  # Handles parsing of CVS specs, checkouts and installation of triggers script
  #
  # format of spec is cvsroot:module
  # examples
  # :local:/cvsroot/damagecontrol:damagecontrol
  # :pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol:damagecontrol
  # if pserver is used, the user is assumed to already be authenticated with cvs login
  # prior to starting damagecontrol
  class CVS < SCM
  
    include FileUtils
  
    def handles_spec?(spec)
      parse_spec(spec)
    end
    
    # parses the spec into tokens
    # [protocol, user, host, path, module]
    #
    def parse_spec(spec)
      md = case
        when spec =~ /^:local:/   then /^:(local):(.*):(.*)$/.match(spec)
        when spec =~ /^:ext:/     then /^:(ext):(.*)@(.*):(.*):(.*)$/.match(spec)
        when spec =~ /^:pserver:/ then /^:(pserver):(.*)@(.*):(.*):(.*)$/.match(spec)
      end
      result = case
        when spec =~ /^:local:/   then [md[1], nil, nil, md[2], md[3]]
        when spec =~ /^:ext:/     then md[1..5]
        when spec =~ /^:pserver:/ then md[1..5]
      end
    end

    def cvsroot(spec)
      /(.*):[A-Za-z]/.match(spec)[1]
    end
    
    def protocol(spec)
      parse_spec(spec)[0]
    end

    def user(spec)
      parse_spec(spec)[1]
    end

    def host(spec)
      parse_spec(spec)[2]
    end

    def path(spec)
      parse_spec(spec)[3]
    end

    def mod(spec)
      parse_spec(spec)[4]
    end

    def checkout_command(spec)
      "-d #{cvsroot(spec)} checkout #{mod(spec)}"
    end

    def update_command(spec)
      "-d #{cvsroot(spec)} update -d -P"
    end
    
    def checkout(spec, directory, &proc)
      directory = File.expand_path(directory)
      File.makedirs(directory)
      Dir.chdir(directory)

      if(checked_out?(directory, spec))
        cvs(update_command(spec), &proc)
      else
        cvs(checkout_command(spec), &proc)
      end
    end

    # Installs and activates the trigger script in the repository
    # for a certain module. Upon subsequent checkins, the damage
    # control server will be notified over a socket and start
    # building
    #
    # @param directory where to temporarily check out during install
    # @param project_name a human readable name for the module
    # @param spec full SCM spec (example: :local:/cvsroot/picocontainer:pico)
    # @param build_command_line command line that will run the build
    # @param relative_path relative path in dc's checkout where build
    #        command will be executed from
    # @param host where the dc server is running
    # @param port where the dc server is listening
    # @param nc_exe_file where nc.exe file can be copied from (only needed for windows)
    #
    # @block &proc a block that can handle the output (should typically log to file)
    #
    def install_trigger(
      directory, \
      project_name, \
      spec, \
      build_command_line, \
      dc_host="localhost", \
      dc_port="4711", \
      relative_path=".", \
      nc_exe_file="", \
      &proc
    )
      directory = File.expand_path(directory)
      checkout("#{cvsroot(spec)}:CVSROOT", directory, &proc)
      Dir.chdir("#{directory}/CVSROOT")
      File.open("#{directory}/CVSROOT/loginfo", File::WRONLY | File::APPEND) do |file|
        script = BuildBootstrapper.new.trigger_command(project_name, spec, build_command_line, relative_path, nc_command(spec), dc_host, dc_port, path_separator)
        file.puts("#{mod(spec)} #{script}")
      end

      if(windows?)
        # install nc.exe
        File.copy( "#{nc_exe_file}", "#{directory}/CVSROOT/nc.exe" )
        system("cvs -d#{cvsroot(spec)} add -kb nc.exe")

        # tell cvs to keep a non-,v file in the central repo
        File.open("checkoutlist", File::WRONLY | File::APPEND) do |file|
          file.puts("nc.exe")
        end
        Dir.chdir("#{directory}/CVSROOT")
        system("cvs commit -m \"added damagecontrol\"")
      end
    end
    
    def nc_command(spec)
      if(windows?)
        "#{path(spec)}/CVSROOT/nc.exe".gsub('/',path_separator)
      else
        "nc"
      end
    end
    
    def checked_out?(directory, spec)
      rootcvs = File.expand_path("#{directory}/#{mod(spec)}/CVS/Root")
      File.exists?(rootcvs)
    end
  
    def cvs(cmd)
      cmd = "cvs #{cmd}"
      puts cmd
      io = IO.popen(cmd) do |io|
        io.each_line do |progress|
          yield progress
        end
      end
    end
    
  end   
end