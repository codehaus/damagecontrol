require 'rscm/abstract_scm'

require 'rscm/path_converter'
require 'rscm/line_editor'
require 'rscm/cvs/cvs_log_parser'

module RSCM

  class CVS < AbstractSCM

    include RSCM::PathConverter
    include RSCM::LineEditor

  public
    attr_accessor :cvsroot
    attr_accessor :cvsmodule
    attr_accessor :cvsbranch
    attr_accessor :cvspassword
    
    def name
      "CVS"
    end
    
    def import(dir, message)
      modulename = File.basename(dir)
      cvs(dir, "import -m \"#{message}\" #{modulename} VENDOR START")
    end
    
    def add(checkout_dir, relative_filename)
      cvs(checkout_dir, "add #{relative_filename}")
    end

    # The extra simulate parameter is not in accordance with the RSCM scm API,
    # but it's optional and is only being used from within this class (uptodate? method).
    def checkout(checkout_dir, scm_to_time=nil, simulate=false, &line_proc)
      checked_out_files = []
      if(checked_out?(checkout_dir))
        path_regex = /^[U|P] (.*)/
        cvs(checkout_dir, update_command(scm_to_time), simulate) do |line, err|
          if(line =~ path_regex)
            checked_out_files << $1.chomp
          end
          line_proc.call(line) if block_given?
        end
      else
        prefix = File.basename(checkout_dir)
        path_regex = /^[U|P] #{prefix}\/(.*)/
        # This is a workaround for the fact that -d . doesn't work - must be an existing sub folder.
        mkdir_p(checkout_dir) unless File.exist?(checkout_dir)
        target_dir = File.basename(checkout_dir)
        run_checkout_command_dir = File.dirname(checkout_dir)
        # -D is sticky, but subsequent updates will reset stickiness with -A
        cvs(run_checkout_command_dir, checkout_command(scm_to_time, target_dir), simulate) do |line, err|
          if(line =~ path_regex)
            checked_out_files << $1.chomp
          end
          line_proc.call(line) if block_given?
        end
      end
      checked_out_files.sort!
    end
    
    def commit(checkout_dir, message, &proc)
      cvs(checkout_dir, commit_command(message), &proc)
    end

    def uptodate?(checkout_dir)
      if(!checked_out?(checkout_dir))
        return false
      end

      # simulate a checkout
      files = checkout(
        checkout_dir,
        nil,
        true
      )
      files.empty?
    end

    def changesets(checkout_dir, scm_from_time, scm_to_time, files, &line_proc)
      begin
        parse_log(checkout_dir, new_changes_command(scm_from_time, scm_to_time, files), &line_proc)
      rescue => e
        parse_log(checkout_dir, old_changes_command(scm_from_time, scm_to_time, files), &line_proc)
      end
    end
    
    def install_trigger(trigger_command, trigger_files_checkout_dir, &line_proc)
      raise "cvsmodule can't be null or empty" if (cvsmodule.nil? || cvsmodule == "")

      cvsroot_cvs = create_cvsroot_cvs
      cvsroot_cvs.checkout(trigger_files_checkout_dir, nil, &line_proc)
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
      loginfo_line = "#{cvsmodule} #{trigger_command}"
      regex = Regexp.new(Regexp.escape(loginfo_line))

      cvsroot_cvs = create_cvsroot_cvs
      begin
        cvsroot_cvs.checkout(trigger_files_checkout_dir, nil, &line_proc)
        loginfo = File.join(trigger_files_checkout_dir, "loginfo")
        return false if !File.exist?(loginfo)

        # returns true if commented out. doesn't modify the file.
        in_local_copy = comment_out(File.new(loginfo), regex, "# ", "")
        # Also verify that loginfo has been committed back to the repo
        entries = File.join(trigger_files_checkout_dir, "CVS", "Entries")
        committed = File.mtime(entries) >= File.mtime(loginfo)

        in_local_copy && committed
      rescue Exception => e
        $stderr.puts(e.message)
        $stderr.puts(e.backtrace.join("\n"))
        false
      end
    end

    def uninstall_trigger(trigger_command, trigger_files_checkout_dir, &line_proc)
      loginfo_line = "#{cvsmodule} #{trigger_command}"
      regex = Regexp.new(Regexp.escape(loginfo_line))

      cvsroot_cvs = create_cvsroot_cvs
      cvsroot_cvs.checkout(trigger_files_checkout_dir, nil, &line_proc)
      loginfo_path = File.join(trigger_files_checkout_dir, "loginfo")
      File.comment_out(loginfo_path, regex, "# ")
      with_working_dir(trigger_files_checkout_dir) do
        commit(trigger_files_checkout_dir, "Uninstalled trigger for CVS module '#{cvsmodule}'")
      end
      raise "Couldn't uninstall/commit trigger to loginfo" if trigger_installed?(trigger_command, trigger_files_checkout_dir)
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
      "log #{branch_option}-N -S #{period_option(scm_from_time, scm_to_time)}"
    end
    
    def old_changes_command(scm_from_time, scm_to_time, files)
      # Many servers don't support the new -S option
      "log #{branch_option}-N #{period_option(scm_from_time, scm_to_time)}"
    end
    
    def branch_specified?
      cvsbranch && cvsbranch.strip != ""
    end

    def branch_option
      if branch_specified? then "-r#{cvsbranch} " else "" end
    end
    
    def update_command(scm_to_time)
      # get a clean copy
      "update #{branch_option}#{to_time_option(scm_to_time)} -d -P -A"
    end
    
    def checkout_command(scm_to_time, target_dir)
      "checkout #{branch_option}#{to_time_option(scm_to_time)} -d #{target_dir} #{cvsmodule}"
    end
    
    def parse_log(checkout_dir, cmd, &proc)
      logged_command_line = command_line(hidden_password, cmd)
      yield logged_command_line if block_given?

      execed_command_line = command_line(cvspassword, cmd)
      changesets = nil
      with_working_dir(checkout_dir) do
        IO.popen(execed_command_line) do |stdout, process|
          parser = CVSLogParser.new(stdout)
          parser.cvspath = path
          parser.cvsmodule = cvsmodule
          changesets = parser.parse_changesets
        end
      end
      changesets
    end

    def cvs(dir, cmd, simulate=false)
      dir = File.expand_path(dir)
      logged_command_line = command_line(hidden_password, cmd, simulate)
      if block_given?
        yield logged_command_line
      end
      execed_command_line = command_line(cvspassword, cmd, simulate)
      with_working_dir(dir) do
        IO.popen(execed_command_line) do |stdout|
          stdout.each_line do |progress|
            yield progress if block_given?
          end
        end
      end
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
    end
    
  private
  
    def command_line(password, cmd, simulate=false)
      cvs_options = simulate ? "-n" : ""
      "cvs \"-d#{cvsroot_with_password(password)}\" #{cvs_options} -q #{cmd}"
    end

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

  # Convenience factory method used in testing
  def CVS.local(cvsroot_dir, cvsmodule)
    cvs = CVS.new
    cvsroot_dir = RSCM::PathConverter.filepath_to_nativepath(cvsroot_dir, true)
    cvs.cvsroot = ":local:#{cvsroot_dir}"
    cvs.cvsmodule = cvsmodule
    cvs
  end
end
