require 'damagecontrol/scm/SCM'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/core/BuildBootstrapper'
require 'damagecontrol/util/Logging'
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
    include Logging
  
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
    
    def changes(spec, checkoutdirectory, time_before, time_after)
      with_working_dir(checkoutdirectory) do
        cvs_with_io(changes_command(time_before, time_after)) do |io|
          parser = CVSLogParser.new
          parser.cvspath = path(spec)
          parser.cvsmodule = mod(spec)
          parser.parse_log(io)
        end
      end
    end
    
    def changes_command(time_before, time_after)
      "log -d\"#{cvsdate(time_before)}<=#{cvsdate(time_after)}\""
    end
    
    def cvsdate(time)
      # CVS wants all dates as UTC.
      time.utc.strftime("%Y-%m-%d %H:%M:%S UTC")
    end
    
    def commit(directory, message, &proc)
      with_working_dir(directory) do
        cvs(commit_command(message), &proc)
      end
    end

    def commit_command(message)
      "commit -m \"#{message}\""
    end

    def checkout_command(scm_spec, directory)
      "-d#{cvsroot(scm_spec)} checkout #{mod(scm_spec)}"
    end

    def update_command(scm_spec)
      "-d#{cvsroot(scm_spec)} update -d -P"
    end
    
    def is_local_connection_method(scm_spec)
      scm_spec =~ /^:local:/
    end
    
    def checkout(scm_spec, directory, &proc)
      scm_spec = to_os_path(scm_spec) if is_local_connection_method(scm_spec)
      directory = to_os_path(File.expand_path(directory))
      if(checked_out?(directory, scm_spec))
        with_working_dir(directory) do
          cvs(update_command(scm_spec), &proc)
        end
      else
        topdir = to_os_path(File.expand_path(directory + "/.."))
        with_working_dir(topdir) do
          cvs(checkout_command(scm_spec, directory), &proc)
          # Now just move the directory. Fix for http://jira.codehaus.org/secure/ViewIssue.jspa?key=DC-44
          mod_directory = to_os_path(File.expand_path(mod(scm_spec)))
          if (mod_directory != directory)
            begin
              File.move(mod_directory, directory)
            rescue NotImplementedError
              File.rename(mod_directory, directory)
            end
          end
        end
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
      dc_url="http://localhost:4711/private/xmlrpc", \
      nc_exe_file="#{damagecontrol_home}/bin/nc.exe", \
      &proc
    )
      directory = File.expand_path(directory)
      checkout("#{cvsroot(scm_spec)}:CVSROOT", directory, &proc)
      with_working_dir(directory) do
        # install trigger command
        File.open("#{directory}/loginfo", File::WRONLY | File::APPEND) do |file|
          trigger_command = trigger_command(project_name, scm_spec, dc_url)
          file.puts("#{mod(scm_spec)} #{trigger_command}")
        end

        # install trigger script
        File.open(trigger_script_name, "w") do |io|
          io.puts(trigger_script)
        end
        system("cvs -d#{cvsroot(scm_spec)} add #{trigger_script_name}")

        checkoutlist = File.open("checkoutlist", File::WRONLY | File::APPEND) do |file|
          file.puts(File.basename(trigger_script_name))
        end

        system("cvs commit -m \"Installed damagecontrol trigger for #{project_name}\"")
      end
    end
    
    def conf_script(scm_spec, conf_file_name)
      to_os_path("#{path(scm_spec)}/CVSROOT/#{conf_file_name}")
    end
    
    def checked_out?(directory, scm_spec)
      rootcvs = File.expand_path("#{directory}/CVS/Root")
      File.exists?(rootcvs)
    end
    
    def trigger_script_name
      "dctrigger.rb"
    end
    
    def trigger_command(project_name, scm_spec, dc_url)
      if(windows?)
        to_os_path("#{path(scm_spec)}/CVSROOT/#{trigger_script_name}") + " #{dc_url} #{project_name}"
      else
        "ruby $CVSROOT/CVSROOT/#{trigger_script_name} #{dc_url} #{project_name}"
      end
    end

    def trigger_script
      %{
        require 'xmlrpc/client'
  
        url = ARGV[0]
        project_name = ARGV[1]

        puts "Triggering DamageControl build to \#{url} for project \#{project_name}"
        client = XMLRPC::Client.new2(url)
        build = client.proxy("build")
        result = build.trig(project_name, Time.now.utc.strftime("%Y%m%d%H%M%S"))
        puts result
      }
    end
    
    def cvs(cmd, &proc)
      cvs_with_io(cmd) do |io|
        io.each_line do |progress|
          if block_given? then yield progress else logger.debug(progress) end
        end
      end
    end
  
    def cvs_with_io(cmd, &proc)
      cmd = "cvs -q #{cmd} 2>&1"

      logger.debug "executing #{cmd}"
      ret = nil
      io = IO.popen("#{cmd}") do |io|
        ret = yield io
      end
      raise SCMError.new("#{cmd} failed with code #{$?.to_s}") if $? != 0
      logger.debug "executed #{cmd}"
      ret
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
    
    def split_entries(log_entry)
      entries = [""]
      log_entry.each_line do |line|
        if line=~/----*/
          entries << ""
        else
          entries[entries.length-1] << line
        end
      end
      entries
    end
    
    def parse_modifications(log_entry)
      entries = split_entries(log_entry)

      file = nil
      entries[0].each_line do |line|
        if line =~ /RCS file: (.*),v/
          file = $1
        end
      end
      
      modifications = []
      
      entries[1..entries.length].each do |entry|
        modification = parse_modification(entry)
        modification.path = make_relative_to_module(file)
        modifications<<modification
      end
      
      modifications
    end
    
    attr_accessor :cvspath
    attr_accessor :cvsmodule
    
    def make_relative_to_module(file)
      return file if cvspath.nil? || cvsmodule.nil?
      # clean away windows backslashes
      cvspath.gsub!(/\\/, "/")
      file.gsub(/\\/, "/").gsub(/^#{cvspath}\/#{cvsmodule}\//, "")
    end
    
    def parse_modification(modification_entry)
      modification = Modification.new
      modification.message = ""
      modification_entry.each_line do |line|
        raise "I've been given crappy input: #{modification_entry}" if line=~/-------*/
      
        if line=~/revision (.*)/
          modification.revision = $1
        elsif line=~/date: (.*);  author: (.*);  state: (.*);(.*)/
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
