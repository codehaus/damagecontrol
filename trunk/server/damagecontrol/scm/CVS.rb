require 'stringio'
require 'pebbles/Pathutils'
require 'damagecontrol/scm/AbstractSCM'
require 'damagecontrol/scm/CVSLogParser'
require 'damagecontrol/scm/Changes'
require 'damagecontrol/util/FileUtils'

module DamageControl

  # Handles parsing of CVS roots, checkouts and installation of trigger scripts
  class CVS < AbstractSCM
    include FileUtils
    include Pebbles::Pathutils

  public
    attr_accessor :cvsbranch
    attr_accessor :cvsroot
    attr_accessor :cvspassword
    attr_accessor :cvsmodule
    attr_accessor :rsh_client
    attr_accessor :cvs_executable
    
    # TODO: refactor. This is ugly!
    def add_or_edit_and_commit_file(checkout_dir, relative_filename, content)
      existed = false
      with_working_dir(checkout_dir) do
        File.mkpath(File.dirname(relative_filename))
        existed = File.exist?(relative_filename)
        File.open(relative_filename, "w") do |file|
          file.puts(content)
        end
      end
      cvs(checkout_dir, "add #{relative_filename}") unless(existed)

      message = existed ? "editing" : "adding"

      cvs(checkout_dir, "com -m \"#{message} #{relative_filename}\"")
    end

    def cvs_executable
      return "cvs" if !defined?(@cvs_executable) || @cvs_executable.nil?
      @cvs_executable
    end

    def import(dir)
      modulename = File.basename(dir)
      cvs(dir, "import -m \"initial import\" #{modulename} VENDOR START")
    end

    def changesets(checkout_dir, from_time, to_time, &proc)
      # exclude commits that occured on from_time
      from_time = from_time + 1
      begin
        parse_log(checkout_dir, new_changes_command(from_time, to_time), &proc)
      rescue Pebbles::ProcessFailedException => e
        parse_log(checkout_dir, old_changes_command(from_time, to_time), &proc)
      end
    end
    
    def uptodate?(checkout_dir, start_time, end_time)
      if(!checked_out?(checkout_dir))
        # might as well check it out if it isn't checked out
        checkout(checkout_dir)
        false
      end

      changesets = changesets(
        checkout_dir,
        start_time,
        end_time
      )
      changesets.empty?
    end

    def new_process(checkout_dir)
      p = Pebbles::Process.new
      p.working_dir = checkout_dir
      p.environment = environment
      p
    end
    
    def parse_log(checkout_dir, cmd, &proc)
      if block_given? then yield "#{cvs_cmd_without_password(cmd)}\n" else logger.debug("#{cvs_cmd_without_password(cmd)}\n") end
      
      new_process(checkout_dir).execute(cvs_cmd_with_password(cmd, cvspassword)) do |stdin, stdout, stderr|
        threads = []
        threads << Thread.new do
          stderr.each_line do |line|
            if block_given? then yield line else logger.debug(line) end
          end
        end
        changesets = nil
        threads << Thread.new do
          parser = CVSLogParser.new(stdout)
          parser.cvspath = path
          parser.cvsmodule = cvsmodule
          changesets = parser.parse_changesets
        end
        threads.each{|t| t.join}
        changesets
      end
    end
    
    def checkout(checkout_dir, time = nil, &proc)
      if(checked_out?(checkout_dir))
        cvs(checkout_dir, update_command(time), &proc)
      else
        # This is a workaround for the fact that -d . doesn't work - must be an existing sub folder.
        mkdir_p(checkout_dir) unless File.exist?(checkout_dir)
        target_dir = File.basename(checkout_dir)
        run_checkout_command_dir = File.dirname(checkout_dir)
        # -D is sticky, but subsequent updates will reset stickiness with -A
        cvs(run_checkout_command_dir, checkout_command(nil, target_dir), &proc)
      end
    end
    
    def commit(checkout_dir, message, &proc)
      cvs(checkout_dir, commit_command(message), &proc)
    end

    def can_install_trigger?
      begin
        exists?
      rescue
        false
      end
    end
    
    # Installs and activates the trigger script in the repository
    # for this SCM. Upon subsequent checkins, the damage
    # control server will be notified over a XML-RPC and start
    # put a new request on the build request queue.
    #
    # @param damagecontrol_install_dir where DC is installed
    # @trigger_files_checkout_dir where the SCM can check out admin files.
    #   This may be ignored by some SCMs (like SVN), but some need it, and it is therefore in the API.
    #   CVS will check out the CVSROOT admin files here. It is recommended that this
    #   dir is a sibling dir to the checkout_dir
    # @param trigger_xml_rpc_url where the dc server is running
    #
    # @block &proc a block that can handle the output (should typically log to file)
    #
    def install_trigger(damagecontrol_install_dir, project_name, trigger_files_checkout_dir, trigger_xml_rpc_url, &proc)
      raise "project_name can't be null or empty" if (project_name.nil? || project_name == "")
      raise "cvsmodule can't be null or empty" if (cvsmodule.nil? || cvsmodule == "")

      cvsroot_cvs = create_cvsroot_cvs
      cvsroot_cvs.checkout(trigger_files_checkout_dir, &proc)
      with_working_dir(trigger_files_checkout_dir) do
        # install trigger command
        File.open("loginfo", File::WRONLY | File::APPEND) do |file|
          file.puts("#{cvsmodule} #{trigger_command(damagecontrol_install_dir, project_name, trigger_xml_rpc_url)}")
        end
        system("#{cvs_executable} commit -m \"Installed DamageControl trigger for #{project_name}\"")
      end
      raise "Couldn't install/commit trigger to loginfo" unless trigger_installed?(trigger_files_checkout_dir, project_name)
    end
    
    def trigger_installed?(trigger_files_checkout_dir, project_name)
      cvsroot_cvs = create_cvsroot_cvs
      begin
        cvsroot_cvs.checkout(trigger_files_checkout_dir)
        loginfo = File.join(trigger_files_checkout_dir, "loginfo")
        return false if !File.exist?(loginfo)
        loginfo_file = File.new(loginfo)
        loginfo_content = loginfo_file.read
        loginfo_file.close
        in_local_copy = trigger_in_string?(loginfo_content, project_name)
        entries = File.join(trigger_files_checkout_dir, "CVS", "Entries")
        
        # Also verify that loginfo has been committed back to the repo
        committed = File.mtime(entries) >= File.mtime(loginfo)
        in_local_copy && committed
      rescue
        false
      end
    end

    def uninstall_trigger(trigger_files_checkout_dir, project_name)
      cvsroot_cvs = create_cvsroot_cvs
      cvsroot_cvs.checkout(trigger_files_checkout_dir)
      loginfo_file = File.new(File.join(trigger_files_checkout_dir, "loginfo"))
      loginfo_content = loginfo_file.read
      loginfo_file.close
      modified_loginfo = disable_trigger_from_string(loginfo_content, project_name, Time.new.utc)
      loginfo_file = File.new(File.join(trigger_files_checkout_dir, "loginfo"), "w")
      loginfo_file.write(modified_loginfo)
      loginfo_file.close
      with_working_dir(trigger_files_checkout_dir) do
        system("#{cvs_executable} commit -m \"Disabled DamageControl trigger for #{project_name}\"")
      end
      raise "Couldn't uninstall/commit trigger to loginfo" unless !trigger_installed?(trigger_files_checkout_dir, project_name)
    end

    def create
      raise "Can't create CVS repository for #{cvsroot}" unless can_create?
      File.mkpath(path)
      cvs(path, "-d#{cvsroot} init")
    end
    
    def can_create?
      begin
        local?
      rescue
        false
      end
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
    
    def new_changes_command(from_time, to_time)
      # https://www.cvshome.org/docs/manual/cvs-1.11.17/cvs_16.html#SEC144
      # -N => Suppress the header if no revisions are selected.
      # -S => Do not print the list of tags for this file.
      "log #{branch_option}-N -S -d\"#{cvsdate(from_time)}<=#{cvsdate(to_time)}\""
    end
    
    def branch_specified?
      cvsbranch && cvsbranch.strip != ""
    end

    def branch_option
      if branch_specified? then "-r#{cvsbranch} " else "" end
    end
    
    def old_changes_command(from_time, to_time)
      # Many servers don't support the new -S option
      "log #{branch_option}-N -d\"#{cvsdate(from_time)}<=#{cvsdate(to_time)}\""
    end
    
    def update_command(time)
      "update #{branch_option}#{time_option(time)} -d -P -A"
    end
    
    def checkout_command(time, target_dir)
      "checkout #{branch_option}#{time_option(time)} -d #{target_dir} #{cvsmodule}"
    end
    
    def cvs_cmd_with_password(cmd, password)
      "#{cvs_executable} -q -d'#{cvsroot_with_password(password)}' #{cmd}"
    end
    
    def cvs_cmd_without_password(cmd)
      cvs_cmd_with_password(cmd, '********')
    end
    
    def environment
      env = {}
      env["CVS_RSH"] = rsh_client if rsh_client && rsh_client != ""
      env
    end
    
    def cvs(dir, cmd)
      if block_given? then yield "#{cvs_cmd_without_password(cmd)}\n" else logger.debug("#{cvs_cmd_without_password(cmd)}\n") end
      cmd_with_io(dir, cvs_cmd_with_password(cmd, cvspassword), environment) do |io|
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
    
    def checked_out?(checkout_dir)
      rootcvs = File.expand_path("#{checkout_dir}/CVS/Root")
      File.exists?(rootcvs)
    end
        
    def cvsroot_with_password(password)
      if local?
        cvsroot
      elsif password && password != ""
        protocol, user, host, path = parse_cvsroot(cvsroot)
        ":#{protocol}:#{user}:#{password}@#{host}:#{path}"
      else
        cvsroot
      end
    end
    
  private

    def create_cvsroot_cvs
      cvs = CVS.new
      cvs.cvsroot = self.cvsroot
      cvs.cvsmodule = "CVSROOT"
      cvs.cvspassword = self.cvspassword
      cvs
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
      parse_cvsroot(cvsroot)[3]
    end
    
    def protocol
      parse_cvsroot(cvsroot)[0]
    end
    
    # parses the cvsroot into tokens
    # [protocol, user, host, path]
    #
    def parse_cvsroot(cvsroot)
      md = case
        when cvsroot =~ /^:local:/   then /^:(local):(.*)/.match(cvsroot)
        when cvsroot =~ /^:ext:/     then /^:(ext):(.*)@(.*):(.*)/.match(cvsroot)
        when cvsroot =~ /^:pserver:/ then /^:(pserver):(.*)@(.*):(.*)/.match(cvsroot)
      end
      result = case
        when cvsroot =~ /^:local:/   then [md[1], nil, nil, md[2]]
        when cvsroot =~ /^:ext:/     then md[1..4]
        when cvsroot =~ /^:pserver:/ then md[1..4]
        else ["local", nil, nil, cvsroot]
      end
    end
  end

  ##################################################################################
  # This is only used during testing
  ##################################################################################

  class LocalCVS < CVS
    def initialize(cvsroot_dir, cvsmodule)
      super()
      cvsroot_dir = filepath_to_nativepath(cvsroot_dir, true)
      self.cvsroot = ":local:#{cvsroot_dir}"
      self.cvsmodule = cvsmodule
    end
  end
end
