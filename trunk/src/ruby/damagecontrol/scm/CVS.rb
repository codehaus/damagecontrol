require 'damagecontrol/scm/SCM'
require 'damagecontrol/FileUtils'
require 'damagecontrol/BuildBootstrapper'
require 'ftools'

module DamageControl

  # Handles parsing of CVS specs, checkouts and installation of triggers script
  #
  # format of scm_spec is cvsroot:module
  # examples
  # :local:/cvsroot/damagecontrol:damagecontrol
  # :pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol:damagecontrol
  # if pserver is used, the user is assumed to already be authenticated with cvs login
  # prior to starting damagecontrol
  class CVS < SCM
  
    include FileUtils
  
    def handles_spec?(scm_spec)
      parse_spec(scm_spec)
    end
    
    # parses the spec into tokens
    # [protocol, user, host, path, module]
    #
    def parse_spec(scm_spec)
      md = case
        when scm_spec =~ /^:local:/   then /^:(local):(.*):(.*)$/.match(scm_spec)
        when scm_spec =~ /^:ext:/     then /^:(ext):(.*)@(.*):(.*):(.*)$/.match(scm_spec)
        when scm_spec =~ /^:pserver:/ then /^:(pserver):(.*)@(.*):(.*):(.*)$/.match(scm_spec)
      end
      result = case
        when scm_spec =~ /^:local:/   then [md[1], nil, nil, md[2], md[3]]
        when scm_spec =~ /^:ext:/     then md[1..5]
        when scm_spec =~ /^:pserver:/ then md[1..5]
      end
    end

    def branch(scm_spec)
      # TODO: add support for branches in the scm_spec
      "MAIN"
    end

    def cvsroot(scm_spec)
      /(.*):[A-Za-z]/.match(scm_spec)[1]
    end
    
    def protocol(scm_spec)
      parse_spec(scm_spec)[0]
    end

    def user(scm_spec)
      parse_spec(scm_spec)[1]
    end

    def host(scm_spec)
      parse_spec(scm_spec)[2]
    end

    def path(scm_spec)
      parse_spec(scm_spec)[3]
    end

    def mod(scm_spec)
      parse_spec(scm_spec)[4]
    end

    def checkout_command(scm_spec, directory)
      "-d#{cvsroot(scm_spec)} checkout #{mod(scm_spec)}"
    end

    def update_command(scm_spec)
      "-d#{cvsroot(scm_spec)} update -d -P"
    end
    
    def checkout(scm_spec, directory, &proc)
      scm_spec = to_os_path(scm_spec)
      directory = to_os_path(File.expand_path(directory))
      if(checked_out?(directory, scm_spec))
        File.makedirs(directory)
        Dir.chdir(directory)
        cvs(update_command(scm_spec), &proc)
      else
        File.makedirs(directory + "/..")
        Dir.chdir(directory + "/..")
        cvs(checkout_command(scm_spec, directory), &proc)
        # Now just move the directory. Fix for http://jira.codehaus.org/secure/ViewIssue.jspa?key=DC-44
        mod_directory = to_os_path(File.expand_path(mod(scm_spec)))

        moved = File.move(mod_directory, directory)
puts "#{moved} MOVINNG #{mod_directory} --> #{directory}"
      end
    end

    # Installs and activates the trigger script in the repository
    # for a certain module. Upon subsequent checkins, the damage
    # control server will be notified over a socket and start
    # building
    #
    # @param directory where to temporarily check out during install
    # @param project_name a human readable name for the module
    # @param scm_spec full SCM spec (example: :local:/cvsroot/picocontainer:pico)
    # @param build_command_line command line that will run the build
    # @param host where the dc server is running
    # @param port where the dc server is listening
    # @param nc_exe_file where nc.exe file can be copied from (only needed for windows)
    #
    # @block &proc a block that can handle the output (should typically log to file)
    #
    def install_trigger(
      directory, \
      project_name, \
      scm_spec, \
      build_command_line, \
      nag_email, \
      dc_host="localhost", \
      dc_port="4711", \
      nc_exe_file="#{damagecontrol_home}/bin/nc.exe", \
      &proc
    )
      directory = File.expand_path(directory)
      checkout("#{cvsroot(scm_spec)}:CVSROOT", directory, &proc)
      Dir.chdir("#{directory}")

      # install trigger command
      File.open("#{directory}/loginfo", File::WRONLY | File::APPEND) do |file|
        conf_file = conf_script(scm_spec, BuildBootstrapper.conf_file(project_name))
        trigger_command = BuildBootstrapper.trigger_command(project_name, conf_file, nc_command(scm_spec), dc_host, dc_port)
        file.puts("#{mod(scm_spec)} #{trigger_command}")
      end

      # install conf file
      conf_file_name = BuildBootstrapper.conf_file(project_name)
      conf_file = File.open(conf_file_name, "w")
      build_spec = BuildBootstrapper.build_spec(project_name, scm_spec, build_command_line, nag_email)
      conf_file.puts(build_spec)
      conf_file.flush
      conf_file.close
      system("cvs -d#{cvsroot(scm_spec)} add #{conf_file_name}")

      checkoutlist = File.open("checkoutlist", File::WRONLY | File::APPEND) do |file|
        file.puts(File.basename(conf_file_name))
      end

      if(windows?)
        # install nc.exe
        File.copy(nc_exe_file, "#{directory}/nc.exe" )
        system("cvs -d#{cvsroot(scm_spec)} add -kb nc.exe")

        # tell cvs to keep a non-,v file in the central repo
        File.open("checkoutlist", File::WRONLY | File::APPEND) do |file|
          file.puts(File.basename(nc_exe_file))
        end
      end
      Dir.chdir("#{directory}")
      system("cvs commit -m \"Installed damagecontrol trigger for #{project_name}\"")
    end
    
    def nc_command(scm_spec)
      if(windows?)
        to_os_path("#{path(scm_spec)}/CVSROOT/nc.exe")
      else
        "nc"
      end
    end
    
    def conf_script(scm_spec, conf_file_name)
      if(windows?)
        to_os_path("#{path(scm_spec)}/CVSROOT/#{conf_file_name}")
      else
        "cat"
      end
    end
    
    def checked_out?(directory, scm_spec)
      rootcvs = File.expand_path("#{directory}/CVS/Root")
      File.exists?(rootcvs)
    end
  
    def cvs(cmd, &proc)
      cmd = "cvs #{cmd} 2>&1"
      io = IO.foreach("|#{cmd}") do |progress|
        if block_given? then yield progress else puts progress end
      end
      raise SCMError.new("#{cmd} failed") if $? != 0
    end
    
  end
  
  class CVSLogParser
    def parse_log(io)
      modifications = []
      while(log_entry = read_log_entry(io))
        modifications += parse_modifications(log_entry)
      end
      modifications
    end
    
    def read_log_entry(io)
      log_entry = ""
      io.each_line do |line|
        return log_entry if line=~/====*/
        log_entry<<line
      end
      return nil
    end
    
    def parse_modifications(log_entry)
      file = nil
      log_entry.each_line do |line|
        if line =~ /RCS file: (.*),v/
          file = $1
        end
        break if line=~/----*/
      end
      modifications = []
      modification_entry = ""
      log_entry.each_line do |line|
        modification_entry<<line
        if line=~/----*/
          modification = parse_modification(modification_entry)
          modification.path = file
          modifications<<modification
        end
      end
      modifications
    end
    
    def parse_modification(modification_entry)
      modification = Modification.new
      modification.message = ""
      modification_entry.each_line do |line|
        if line=~/revision (.*)/
          modification.revision = $1
        elsif line=~/date: (.*);  author: (.*);  state: (.*);  lines: (.*)/
          modification.time = $1
          modification.developer = $2
        else
          modification.message<<line
        end
      end
      modification
    end
    
  end

end