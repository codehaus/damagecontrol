require 'damagecontrol/util/FileUtils'
require 'damagecontrol/core/BuildBootstrapper'
require 'damagecontrol/util/Logging'
require 'ftools'

module DamageControl

  # Handles parsing of CVS roots, checkouts and installation of trigger scripts
  #
  # If pserver is used, the user is assumed to already be authenticated with cvs login
  # prior to starting damagecontrol. (TODO: fix that!) 
  class CVS
  
    include FileUtils
    include Logging
    
    attr_reader :cvsroot
    
    def initialize(cvsroot, mod, working_dir_root)
      @cvsroot, @mod = cvsroot, mod
      @working_dir_root = to_os_path(File.expand_path(working_dir_root)) unless working_dir_root.nil?
    end
  
    def protocol
      parse_cvsroot[0]
    end

    def user
      parse_cvsroot[1]
    end

    def host
      parse_cvsroot[2]
    end

    def path
      parse_cvsroot[3]
    end

    def mod
      @mod
    end
    
    def working_dir
      File.join(@working_dir_root, mod)
    end
    
    def changes(from_time, to_time)
      with_working_dir(working_dir) do
        cvs_with_io(changes_command(from_time, to_time)) do |io|
          parser = CVSLogParser.new
          parser.cvspath = path
          parser.cvsmodule = mod
          parser.parse_log(io)
        end
      end
    end
    
    def changes_command(from_time, to_time)
      "log -d\"#{cvsdate(from_time)}<=#{cvsdate(to_time)}\""
    end
    
    def cvsdate(time)
      # CVS wants all dates as UTC.
      time.utc.strftime("%Y-%m-%d %H:%M:%S UTC")
    end
    
    def commit(message, &proc)
      with_working_dir(working_dir) do
        cvs(commit_command(message), &proc)
      end
    end

    def commit_command(message)
      "commit -m \"#{message}\""
    end

    def checkout_command
      "-d#{@cvsroot} checkout #{mod}"
    end

    def update_command
      "-d#{@cvsroot} update -d -P"
    end
    
    def is_local_connection_method
      @cvsroot =~ /^:local:/
    end
    
    def checkout(&proc)
      if(checked_out?)
        with_working_dir(working_dir) do
          cvs(update_command, &proc)
        end
      else
        with_working_dir(@working_dir_root) do
          cvs(checkout_command, &proc)
        end
      end
    end
    
    # Installs and activates the trigger script in the repository
    # for a certain module. Upon subsequent checkins, the damage
    # control server will be notified over a socket and start
    # building
    #
    # @param project_name a human readable name for the module
    # @param dc_url where the dc server is running
    #
    # @block &proc a block that can handle the output (should typically log to file)
    #
    def install_trigger(
      project_name, \
      dc_url="http://localhost:4712/private/xmlrpc", \
      &proc
    )
      cvsroot_cvs = CVS.new(@cvsroot, "CVSROOT", @working_dir_root)
      cvsroot_cvs.checkout(&proc)
      with_working_dir(cvsroot_cvs.working_dir) do
        # install trigger command
        File.open("loginfo", File::WRONLY | File::APPEND) do |file|
          trigger_command = trigger_command(project_name, dc_url)
          file.puts("#{mod} #{trigger_command}")
        end

        # install trigger script
        File.open(trigger_script_name, "w") do |io|
          io.puts(trigger_script)
        end
        system("cvs -d#{@cvsroot} add #{trigger_script_name}")

        checkoutlist = File.open("checkoutlist", File::WRONLY | File::APPEND) do |file|
          file.puts(File.basename(trigger_script_name))
        end

        system("cvs commit -m \"Installed damagecontrol trigger for #{project_name}\"")
      end
    end
    
    def trigger_script
%{require 'xmlrpc/client'

url = ARGV[0]
project_name = ARGV[1]

puts "Nudging DamageControl on \#{url} to build project \#{project_name}"
client = XMLRPC::Client.new2(url)
build = client.proxy("build")
result = build.trig(project_name, Time.now.utc.strftime("%Y%m%d%H%M%S"))
puts result
}
    end

    def trigger_installed?(project_name)
      cvsroot_cvs = CVS.new(@cvsroot, "CVSROOT", @working_dir_root)
      cvsroot_cvs.checkout
      loginfo_file = File.new(File.join(cvsroot_cvs.working_dir, "loginfo"))
      loginfo_content = loginfo_file.read
      loginfo_file.close
      trigger_in_string?(loginfo_content, project_name)
    end

    def uninstall_trigger(project_name)
      cvsroot_cvs = CVS.new(@cvsroot, "CVSROOT", @working_dir_root)
      cvsroot_cvs.checkout
      loginfo_file = File.new(File.join(cvsroot_cvs.working_dir, "loginfo"))
      loginfo_content = loginfo_file.read
      loginfo_file.close
      modified_loginfo = disable_trigger_from_string(loginfo_content, project_name, Time.new.utc)
      loginfo_file = File.new(File.join(cvsroot_cvs.working_dir, "loginfo"), "w")
      loginfo_file.write(modified_loginfo)
      loginfo_file.close
      with_working_dir(cvsroot_cvs.working_dir) do
        system("cvs commit -m \"Disabled DamageControl nudger for #{project_name}\"")
      end
    end

    def trigger_in_string?(loginfo_content, project_name)
      disable_trigger_from_string(loginfo_content, project_name, Time.new.utc) != loginfo_content
    end
    
    def disable_trigger_from_string(loginfo_content, project_name, date)
      modified = ""
      loginfo_content.each_line do |line|
        # TODO: couldn't find out how to express this with a single regexp.
        matches = (Regexp.new(".* ruby.*dctrigger.rb http.* #{project_name}$") =~ line) && line[0..0] != "#"
        # The old format - we want to match them to so they get deleted.
        matches = (Regexp.new("^cat .* | nc.*4711$") =~ line) && line[0..0] != "#" unless matches
        if(matches)
          formatted_date = date.strftime("%B %d, %Y")
          modified << "# Disabled by DamageControl on #{formatted_date}\n"
          modified << "##{line}"
        else
          modified << line
        end
      end
      modified
    end
    
    def conf_script(conf_file_name)
      to_os_path("#{path}/CVSROOT/#{conf_file_name}")
    end
    
    def checked_out?
      rootcvs = File.expand_path("#{@working_dir_root}/CVS/Root")
      File.exists?(rootcvs)
    end
        
    def trigger_script_name
      "dctrigger.rb"
    end
    
    def trigger_command(project_name, dc_url)
      "ruby " + to_os_path("#{path}/CVSROOT/#{trigger_script_name}") + " #{dc_url} #{project_name}"
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

      logger.debug("executing #{cmd}")
      ret = nil
      io = IO.popen("#{cmd}") do |io|
        ret = yield io
      end
      raise Exception.new("'#{cmd}' in directory '#{Dir.pwd}' failed with code #{$?.to_s}") if $? != 0
      logger.debug("executed #{cmd}")
      ret
    end

  private

    # parses the cvsroot into tokens
    # [protocol, user, host, path]
    #
    def parse_cvsroot
      md = case
        when @cvsroot =~ /^:local:/   then /^:(local):(.*)/.match(@cvsroot)
        when @cvsroot =~ /^:ext:/     then /^:(ext):(.*)@(.*):(.*)/.match(@cvsroot)
        when @cvsroot =~ /^:pserver:/ then /^:(pserver):(.*)@(.*):(.*)/.match(@cvsroot)
      end
      result = case
        when @cvsroot =~ /^:local:/   then [md[1], nil, nil, md[2]]
        when @cvsroot =~ /^:ext:/     then md[1..4]
        when @cvsroot =~ /^:pserver:/ then md[1..4]
      end
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
