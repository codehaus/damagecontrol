require 'stringio'
require 'damagecontrol/scm/AbstractSCM'
require 'damagecontrol/scm/CVSLogParser'
require 'damagecontrol/scm/Changes'
require 'damagecontrol/util/FileUtils'

module DamageControl

  # Handles parsing of CVS roots, checkouts and installation of trigger scripts
  class CVS < AbstractSCM
    include FileUtils

  public
    attr_reader :mod
    
    def initialize(config_map)
      super(config_map)
      @cvsroot = config_map["cvsroot"] || required_config_param("cvsroot", config_map)
      @mod = config_map["cvsmodule"] || required_config_param("cvsmodule", config_map)
      @password = config_map["cvspassword"]
    end
    
    def changesets(from_time, to_time)
      # exclude commits that occured on from_time
      from_time = from_time + 1

      log = ""
      cvs(working_dir, changes_command(from_time, to_time)) do |line|
        log << line
        #yield line if block_given?
      end
      parser = CVSLogParser.new(StringIO.new(log))
      parser.cvspath = path
      parser.cvsmodule = mod
      parser.parse_changesets
    end
    
    def login_command
      "cvs -d'#{cvsroot_with_password}' login"
    end
    
    def checkout(time = nil, &proc)
      if(checked_out?)
        cvs(working_dir, update_command(time), &proc)
      else
        cvs(checkout_dir, checkout_command(time), &proc)
      end
    end
    
    def commit(message, &proc)
      cvs(working_dir, commit_command(message), &proc)
    end

    def working_dir
      "#{checkout_dir}/#{mod}"
    end
    
    def can_install_trigger?
      exists?
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
    def install_trigger(damagecontrol_install_dir, project_name, dc_url="http://localhost:4712/private/xmlrpc", &proc)
      cvsroot_cvs = create_cvsroot_cvs
      cvsroot_cvs.checkout(&proc)
      with_working_dir(cvsroot_cvs.working_dir) do
        # install trigger command
        File.open("loginfo", File::WRONLY | File::APPEND) do |file|
          file.puts("#{mod} #{trigger_command(damagecontrol_install_dir, project_name, dc_url)}")
        end
        system("cvs commit -m \"Installed DamageControl trigger for #{project_name}\"")
      end
    end
    
    def trigger_installed?(project_name)
      cvsroot_cvs = create_cvsroot_cvs
      cvsroot_cvs.checkout
      loginfo = File.join(cvsroot_cvs.working_dir, "loginfo")
      return false if !File.exist?(loginfo)
      loginfo_file = File.new(loginfo)
      loginfo_content = loginfo_file.read
      loginfo_file.close
      in_local_copy = trigger_in_string?(loginfo_content, project_name)
      entries = File.join(cvsroot_cvs.working_dir, "CVS", "Entries")
      committed = File.mtime(entries) >= File.mtime(loginfo)
      in_local_copy && committed
    end

    def uninstall_trigger(project_name)
      cvsroot_cvs = create_cvsroot_cvs
      cvsroot_cvs.checkout
      loginfo_file = File.new(File.join(cvsroot_cvs.working_dir, "loginfo"))
      loginfo_content = loginfo_file.read
      loginfo_file.close
      modified_loginfo = disable_trigger_from_string(loginfo_content, project_name, Time.new.utc)
      loginfo_file = File.new(File.join(cvsroot_cvs.working_dir, "loginfo"), "w")
      loginfo_file.write(modified_loginfo)
      loginfo_file.close
      with_working_dir(cvsroot_cvs.working_dir) do
        system("cvs commit -m \"Disabled DamageControl trigger for #{project_name}\"")
      end
    end

    def create
      raise "Can't create CVS repository for #{@cvsroot}" unless can_create?
      File.mkpath(path)
      cvs(path, "-d#{cvsroot} init")
    end
    
    def can_create?
      local?
    end

    def exists?
      if(local?)
        File.exists?("#{path}/CVSROOT/loginfo")
      else
        # don't know. assume yes.
        true
      end
    end

  # NOT PART OF PUBLIC API. EXPOSED JUST TO MAKE TESTING EASIER
  # SHOULD IDEALLY BE MOVED TO protected OR private.

    def trigger_in_string?(loginfo_content, project_name)
      disable_trigger_from_string(loginfo_content, project_name, Time.new.utc) != loginfo_content
    end
    
    def disable_trigger_from_string(loginfo_content, project_name, date)
      modified = ""
      loginfo_content.each_line do |line|
        # TODO: couldn't find out how to express this with a single regexp.
        matches = line[0..0] != "#" && line =~ /requestbuild/
        # The old formats - we want to match them to so they get deleted.
        matches = line[0..0] != "#" && line =~ /.*ruby.*dctrigger.rb http.* #{project_name}$/ unless matches
        matches = line[0..0] != "#" && line =~ /^cat .* | nc.*4711$/ unless matches
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
    
    def changes_command(from_time, to_time)
      # https://www.cvshome.org/docs/manual/cvs-1.11.17/cvs_16.html#SEC144
      # -N => Suppress the header if no revisions are selected.
      # -S => Do not print the list of tags for this file.
      "log -N -S -d\"#{cvsdate(from_time)}<=#{cvsdate(to_time)}\""
    end
    
    def update_command(time)
      "update #{time_option(time)} -d -P"
    end
    
    def checkout_command(time)
      "checkout #{time_option(time)} #{mod}"
    end

    def cvs(dir, cmd, &proc)
      cmd_with_password = "cvs -q -d'#{cvsroot}' #{cmd}"
      cmd_without_password = "cvs -q -d'#{cvsroot('********')}' #{cmd}"
      if block_given? then yield "#{cmd_without_password}\n" else logger.debug("#{cmd_without_password}\n") end
      cmd_with_io(dir, cmd_with_password) do |io|
        io.each_line do |progress|
          if block_given? then yield progress else logger.debug(progress) end
        end
      end
    end

  protected
      
    def cvsdate(time)
      return "" unless time
      # CVS wants all dates as UTC.
      time.utc.strftime("%Y-%m-%d %H:%M:%S UTC")
    end
    
    def checked_out?
      rootcvs = File.expand_path("#{working_dir}/CVS/Root")
      File.exists?(rootcvs)
    end
        
  private

    def cvsroot(password=@password)
      if @password && @password != ""
        protocol, user, host, path = parse_cvsroot
        ":#{protocol}:#{user}:#{password}@#{host}:#{path}"
      else
        @cvsroot
      end
    end
    
    def create_cvsroot_cvs
      CVS.new("cvsroot" => @cvsroot, "cvsmodule" => "CVSROOT", "cvspassword" => @password, "checkout_dir" => checkout_dir)
    end

    def time_option(time)
      if time.nil? then "" else "-D \"#{cvsdate(time)}\"" end
    end

    def commit_command(message)
      "commit -m \"#{message}\""
    end

    def local?
      protocol == "local"
    end
    
    def path
      parse_cvsroot[3]
    end
    
    def protocol
      parse_cvsroot[0]
    end
    
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

  ##################################################################################
  # This is only used during testing
  ##################################################################################

  class LocalCVS < CVS
    def initialize(basedir, mod)
      super("cvsroot" => ":local:#{basedir}/cvsroot", "cvsmodule" => mod, "checkout_dir" => "#{basedir}/checkout")
    end

    def import(dir)
      modulename = File.basename(dir)
      cvs(dir, "-d#{cvsroot} import -m \"initial import\" #{modulename} VENDOR START")
    end

    # TODO: refactor. This is ugly!
    def add_or_edit_and_commit_file(relative_filename, content)
      existed = false
      with_working_dir(working_dir) do
        File.mkpath(File.dirname(relative_filename))
        existed = File.exist?(relative_filename)
        File.open(relative_filename, "w") do |file|
          file.puts(content)
        end
      end
      cvs(working_dir, "add #{relative_filename}") unless(existed)

      message = existed ? "editing" : "adding"

      cvs(working_dir, "com -m \"#{message} #{relative_filename}\"")
    end
  end
end
