require 'parsedate'
require 'pebbles/LineEditor'
require 'pebbles/Pathutils'
require 'pebbles/AsyncProcess'
require 'damagecontrol/scm/AbstractSCM'
require 'damagecontrol/scm/CVSLogParser'
require 'damagecontrol/scm/Changes'
require 'damagecontrol/util/FileUtils'

module DamageControl

  # Handles parsing of CVS roots, checkouts and installation of trigger scripts
  class CVS < AbstractSCM
    include ParseDate
    include FileUtils
    include Pebbles::Pathutils
    include Pebbles::LineEditor

  public
    attr_accessor :cvsbranch
    attr_accessor :cvsroot
    attr_accessor :cvspassword
    attr_accessor :cvsmodule
    attr_accessor :rsh_client
    attr_accessor :cvs_executable
    
    def name
      "CVS"
    end
    
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

    def checkout(checkout_dir, scm_from_time, scm_to_time, &line_proc)
      checked_out_files = []
      if(checked_out?(checkout_dir))
        path_regex = /^[U|P] (.*)/
        cvs(checkout_dir, update_command(scm_to_time)) do |line|
          if(line =~ path_regex)
            checked_out_files << $1
          end
          line_proc.call(line) if block_given?
        end
        changesets(checkout_dir, scm_from_time, scm_to_time, checked_out_files, &line_proc)
      else
        path_regex = /^[U|P] checkout\/(.*)/
        # This is a workaround for the fact that -d . doesn't work - must be an existing sub folder.
        mkdir_p(checkout_dir) unless File.exist?(checkout_dir)
        target_dir = File.basename(checkout_dir)
        run_checkout_command_dir = File.dirname(checkout_dir)
        # -D is sticky, but subsequent updates will reset stickiness with -A
        cvs(run_checkout_command_dir, checkout_command(scm_to_time, target_dir)) do |line|
          if(line =~ path_regex)
            checked_out_files << $1
          end
          line_proc.call(line) if block_given?
        end
        # See comment in AbstractSCM.checkout
        most_recent_timestamp(changesets(checkout_dir, scm_from_time, scm_to_time, checked_out_files, &line_proc))
      end
    end
    
    def commit(checkout_dir, message, &proc)
      cvs(checkout_dir, commit_command(message), &proc)
    end

    def changesets(checkout_dir, scm_from_time, scm_to_time, files, &line_proc)
      begin
        parse_log(checkout_dir, new_changes_command(scm_from_time, scm_to_time, files), &line_proc)
      rescue ProcessError => e
        parse_log(checkout_dir, old_changes_command(scm_from_time, scm_to_time, files), &line_proc)
      end
    end
    
    def install_trigger(trigger_command, trigger_files_checkout_dir, &line_proc)
      raise "cvsmodule can't be null or empty" if (cvsmodule.nil? || cvsmodule == "")

      cvsroot_cvs = create_cvsroot_cvs
      cvsroot_cvs.checkout(trigger_files_checkout_dir, nil, nil, &line_proc)
      with_working_dir(trigger_files_checkout_dir) do
        trigger_line = "#{cvsmodule} #{trigger_command}\n"
        File.open("loginfo", File::WRONLY | File::APPEND) do |file|
          file.puts(trigger_line)
        end
        begin
          commit(trigger_files_checkout_dir, "Installed trigger for CVS module '#{cvsmodule}'")
        rescue
          raise "Couldn't commit the trigger back to CVS. Try to manually check out CVSROOT/loginfo, " +
          "add the following line and commit it back:\n\n#{trigger_line}"
        end
      end
    end
    
    def trigger_installed?(trigger_command, trigger_files_checkout_dir, &line_proc)
      regex = /#{cvsmodule} #{trigger_command}/
      cvsroot_cvs = create_cvsroot_cvs
      begin
        cvsroot_cvs.checkout(trigger_files_checkout_dir, nil, nil, &line_proc)
        loginfo = File.join(trigger_files_checkout_dir, "loginfo")
        return false if !File.exist?(loginfo)

        # returns true if commented out. doesn't modify the file.
        in_local_copy = comment_out(File.new(loginfo), regex, "# ", "")
        # Also verify that loginfo has been committed back to the repo
        entries = File.join(trigger_files_checkout_dir, "CVS", "Entries")
        committed = File.mtime(entries) >= File.mtime(loginfo)

        in_local_copy && committed
      rescue Exception => e
        puts e.message
        puts e.backtrace.join("\n")
        false
      end
    end

    def uninstall_trigger(trigger_command, trigger_files_checkout_dir, &line_proc)
      regex = /#{cvsmodule} #{trigger_command}/
      cvsroot_cvs = create_cvsroot_cvs
      cvsroot_cvs.checkout(trigger_files_checkout_dir, nil, nil, &line_proc)
      loginfo_path = File.join(trigger_files_checkout_dir, "loginfo")
      File.comment_out(loginfo_path, regex, "# ")
      with_working_dir(trigger_files_checkout_dir) do
        system("#{cvs_executable} commit -m \"Disabled DamageControl trigger for /#{regex}/\"")
      end
      raise "Couldn't uninstall/commit trigger to loginfo" unless !trigger_installed?(regex, trigger_files_checkout_dir)
    end

    def create
      raise "Can't create CVS repository for #{cvsroot}" unless can_create?
      File.mkpath(path)
      cvs(path, "init")
    end
    
    def can_create?
      begin
        local?
      rescue
        false
      end
    end

    def supports_trigger?
      true
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
    
    def new_changes_command(scm_from_time, scm_to_time, files)
      # https://www.cvshome.org/docs/manual/cvs-1.11.17/cvs_16.html#SEC144
      # -N => Suppress the header if no revisions are selected.
      # -S => Do not print the list of tags for this file.
      "log #{branch_option}-N -S #{period_option(scm_from_time, scm_to_time)}#{files.join(' ')}"
    end
    
    def old_changes_command(scm_from_time, scm_to_time, files)
      # Many servers don't support the new -S option
      "log #{branch_option}-N #{period_option(scm_from_time, scm_to_time)}#{files.join(' ')}"
    end
    
    def branch_specified?
      cvsbranch && cvsbranch.strip != ""
    end

    def branch_option
      if branch_specified? then "-r#{cvsbranch} " else "" end
    end
    
    def update_command(scm_to_time)
      # get a clean copy
      "update #{branch_option}#{to_time_option(scm_to_time)} -d -P -A -C"
    end
    
    def checkout_command(scm_to_time, target_dir)
      "checkout #{branch_option}#{to_time_option(scm_to_time)} -d #{target_dir} #{cvsmodule}"
    end
    
    def environment
      env = {}
      env["CVS_RSH"] = rsh_client if rsh_client && rsh_client != ""
      env
    end
    
    def parse_log(checkout_dir, cmd, &proc)
      changesets = nil

      outproc = Proc.new { |io| 
        parser = CVSLogParser.new(io)
        parser.cvspath = path
        parser.cvsmodule = cvsmodule
        changesets = parser.parse_changesets
      }

      execed_command_line = "cvs -d#{cvsroot_with_password(cvspassword)} #{cmd}"      
      Pebbles::AsyncProcess.new(checkout_dir, execed_command_line, nil, outproc, nil, environment, 60*10).waitfor
      changesets
    end
    
    def cvs(dir, cmd)
      logged_command_line = "cvs -d#{cvsroot_with_password(hidden_password)} #{cmd}"
      if block_given?
        yield logged_command_line
      else 
        logger.debug(logged_command_line) 
      end

      execed_command_line = "cvs -d#{cvsroot_with_password(cvspassword)} #{cmd}"
      outproc = Proc.new { 
        |io| io.each_line { 
          |progress|
            if block_given? then yield progress else logger.debug(progress) end
        }
      }
      Pebbles::AsyncProcess.new(dir, execed_command_line, nil, outproc, nil, environment, 60*10).waitfor
    end

  protected

    def hidden_password
      if(cvspassword && cvspassword != "")
        "********"
      else
        ""
      end
    end
  
    def period_option(scm_from_time, scm_to_time)
      if(scm_from_time.nil? && scm_to_time.nil?)
        ""
      else
        "-d\"#{cvsdate(scm_from_time)}<=#{cvsdate(scm_to_time)}\" " 
      end
    end
      
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
      result = nil
      if local?
        result = cvsroot
      elsif password && password != ""
        protocol, user, host, path = parse_cvsroot(cvsroot)
        result = ":#{protocol}:#{user}:#{password}@#{host}:#{path}"
      else
        result = cvsroot
      end
      
      # convert backslashes before running in shell
      result.gsub(/\\/, '\\\\\\\\')
    end
    
  private

    def create_cvsroot_cvs
      cvs = CVS.new
      cvs.cvsroot = self.cvsroot
      cvs.cvsmodule = "CVSROOT"
      cvs.cvspassword = self.cvspassword
      cvs
    end

    def to_time_option(time)
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
