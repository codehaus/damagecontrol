require 'rscm/abstract_scm'

require 'rscm/path_converter'
require 'rscm/line_editor'
require 'rscm/cvs/cvs_log_parser'

module RSCM

  # RSCM implementation for CVS.
  #
  # You need the cvs executable on the PATH in order for it to work.
  #
  # NOTE: On Cygwin this has to be the win32 build of cvs and not the Cygwin one.
  class CVS < AbstractSCM

  public
    attr_accessor :cvsroot
    attr_accessor :cvsmodule
    attr_accessor :cvsbranch
    attr_accessor :cvspassword
    
    def initialize(cvsroot=nil, cvsmodule=nil, cvsbranch=nil, cvspassword=nil)
      @cvsroot, @cvsmodule, @cvsbranch, @cvspassword = cvsroot, cvsmodule, cvsbranch, cvspassword
    end

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

    # The extra simulate parameter is not in accordance with the AbstractSCM API,
    # but it's optional and is only being used from within this class (uptodate? method).
    def checkout(checkout_dir, simulate=false)
      checked_out_files = []
      if(checked_out?(checkout_dir))
        path_regex = /^[U|P] (.*)/
        cvs(checkout_dir, update_command, simulate) do |line|
          if(line =~ path_regex)
            path = $1.chomp
            yield path if block_given?
            checked_out_files << path
          end
        end
      else
        prefix = File.basename(checkout_dir)
        path_regex = /^[U|P] #{prefix}\/(.*)/
        # This is a workaround for the fact that -d . doesn't work - must be an existing sub folder.
        mkdir_p(checkout_dir) unless File.exist?(checkout_dir)
        target_dir = File.basename(checkout_dir)
        run_checkout_command_dir = File.dirname(checkout_dir)
        # -D is sticky, but subsequent updates will reset stickiness with -A
        cvs(run_checkout_command_dir, checkout_command(target_dir), simulate) do |line|
          if(line =~ path_regex)
            path = $1.chomp
            yield path if block_given?
            checked_out_files << path
          end
        end
      end
      checked_out_files.sort!
    end
    
    def checkout_commandline(to_identifier=Time.infinity)
      "cvs checkout #{branch_option} #{to_option(to_identifier)} #{cvsmodule}"
    end

    def update_commandline
      "cvs update #{branch_option} -d -P -A"
    end

    def commit(checkout_dir, message, &proc)
      cvs(checkout_dir, commit_command(message), &proc)
    end

    def uptodate?(checkout_dir, since)
      if(!checked_out?(checkout_dir))
        return false
      end

      # simulate a checkout
      files = checkout(checkout_dir, true)
      files.empty?
    end

    def changesets(checkout_dir, from_identifier, to_identifier=Time.infinity, files=nil)
puts "CHANGESETS #{from_identifier} - #{to_identifier}"
      begin
        parse_log(checkout_dir, new_changes_command(from_identifier, to_identifier, files))
      rescue => e
        parse_log(checkout_dir, old_changes_command(from_identifier, to_identifier, files))
      end
    end
    
    def apply_label(checkout_dir, label)
      cvs(checkout_dir, "tag -c #{label}")
    end
    
    def install_trigger(trigger_command, trigger_files_checkout_dir)
      raise "cvsmodule can't be null or empty" if (cvsmodule.nil? || cvsmodule == "")

      cvsroot_cvs = create_cvsroot_cvs
      cvsroot_cvs.checkout(trigger_files_checkout_dir)
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
    
    def trigger_installed?(trigger_command, trigger_files_checkout_dir)
      loginfo_line = "#{cvsmodule} #{trigger_command}"
      regex = Regexp.new(Regexp.escape(loginfo_line))

      cvsroot_cvs = create_cvsroot_cvs
      begin
        cvsroot_cvs.checkout(trigger_files_checkout_dir)
        loginfo = File.join(trigger_files_checkout_dir, "loginfo")
        return false if !File.exist?(loginfo)

        # returns true if commented out. doesn't modify the file.
        in_local_copy = LineEditor.comment_out(File.new(loginfo), regex, "# ", "")
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

    def uninstall_trigger(trigger_command, trigger_files_checkout_dir)
      loginfo_line = "#{cvsmodule} #{trigger_command}"
      regex = Regexp.new(Regexp.escape(loginfo_line))

      cvsroot_cvs = create_cvsroot_cvs
      cvsroot_cvs.checkout(trigger_files_checkout_dir)
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

  private

    def cvs(dir, cmd, simulate=false)
      dir = File.expand_path(dir)

      execed_command_line = command_line(cvspassword, cmd, simulate)
      with_working_dir(dir) do
        IO.popen(execed_command_line) do |stdout|
          stdout.each_line do |progress|
            yield progress if block_given?
          end
        end
      end
    end

    def checkout_command(target_dir)
      "checkout #{branch_option} -d #{target_dir} #{cvsmodule}"
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

    def new_changes_command(from_identifier, to_identifier, files)
      # https://www.cvshome.org/docs/manual/cvs-1.11.17/cvs_16.html#SEC144
      # -N => Suppress the header if no revisions are selected.
      # -S => Do not print the list of tags for this file.
      "log #{branch_option} -N -S #{period_option(from_identifier, to_identifier)}"
    end

    def branch_specified?
      cvsbranch && cvsbranch.strip != ""
    end

    def branch_option
      branch_specified? ? "-r#{cvsbranch}" : ""
    end

    def update_command
      # get a clean copy
      "update #{branch_option} -d -P -A"
    end

    def old_changes_command(from_identifier, to_identifier, files)
      # Many servers don't support the new -S option
      "log #{branch_option} -N #{period_option(from_identifier, to_identifier)}"
    end

    def hidden_password
      if(cvspassword && cvspassword != "")
        "********"
      else
        ""
      end
    end
  
    def period_option(from_identifier, to_identifier)
      if(from_identifier.nil? && to_identifier.nil?)
        ""
      else
        "-d\"#{cvsdate(from_identifier)}<=#{cvsdate(to_identifier)}\" " 
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
  
    def command_line(password, cmd, simulate=false)
      cvs_options = simulate ? "-n" : ""
      "cvs \"-d#{cvsroot_with_password(password)}\" #{cvs_options} -q #{cmd}"
    end

    def create_cvsroot_cvs
      CVS.new(self.cvsroot, "CVSROOT", nil, self.cvspassword)
    end

    def to_option(to_identifier)
      option = nil
      if(to_identifier.is_a?(Time))
        option = "-D \"#{cvsdate(to_identifier)}\""
      elsif(to_identifier.is_a?(String))
        option = "-r #{to_identifier}"
      else
        ""
      end
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
    cvsroot_dir = PathConverter.filepath_to_nativepath(cvsroot_dir, true)
    CVS.new(":local:#{cvsroot_dir}", cvsmodule)
  end
end
