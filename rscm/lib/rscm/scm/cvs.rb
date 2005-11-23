require 'stringio'
require 'rscm/base'
require 'rscm/path_converter'
require 'rscm/line_editor'
require 'rscm/scm/cvs_log_parser'

module RSCM

  # RSCM implementation for CVS.
  #
  # You need a cvs executable on the PATH in order for it to work.
  #
  # NOTE: On Cygwin this has to be the win32 build of cvs and not the Cygwin one.
  class Cvs < Base
    attr_accessor :root
    attr_accessor :mod
    attr_accessor :branch
    attr_accessor :password
    
    def initialize(root=nil, mod=nil, branch=nil, password=nil)
      @root, @mod, @branch, @password = root, mod, branch, password
    end

    def import_central(dir, message)
      modname = File.basename(dir)
      cvs(dir, "import -m \"#{message}\" #{modname} VENDOR START")
    end
    
    def add(relative_filename)
      cvs(@checkout_dir, "add #{relative_filename}")
    end

    def move(relative_src, relative_dest)
      FileUtils.mv(@checkout_dir + '/' + relative_src, @checkout_dir + '/' + relative_dest, :force=>true)
      cvs(@checkout_dir, "rm #{relative_src}")
      # This will fail if the directories are new. More advanced support for adding can be added if needed.
      cvs(@checkout_dir, "add #{relative_dest}")
    end

    # The extra simulate parameter is not in accordance with the AbstractSCM API,
    # but it's optional and is only being used from within this class (uptodate? method).
    def checkout(to_identifier=nil, simulate=false)
      checked_out_files = []
      if(checked_out?)
        path_regex = /^[U|P] (.*)/
        cvs(@checkout_dir, update_command(to_identifier), simulate) do |line|
          if(line =~ path_regex)
            path = $1.chomp
            yield path if block_given?
            checked_out_files << path
          end
        end
      else
        prefix = File.basename(@checkout_dir)
        path_regex = /^[U|P] #{prefix}\/(.*)/
        # This is a workaround for the fact that -d . doesn't work - must be an existing sub folder.
        FileUtils.mkdir_p(@checkout_dir) unless File.exist?(@checkout_dir)
        target_dir = File.basename(@checkout_dir)
        run_checkout_command_dir = File.dirname(@checkout_dir)
        # -D is sticky, but subsequent updates will reset stickiness with -A
        cvs(run_checkout_command_dir, checkout_command(target_dir, to_identifier), simulate) do |line|
          if(line =~ path_regex)
            path = $1.chomp
            yield path if block_given?
            checked_out_files << path
          end
        end
      end
      checked_out_files
    end
    
    def commit(message)
      cvs(@checkout_dir, commit_command(message))
    end

    def uptodate?(identifier)
      if(!checked_out?)
        return false
      end

      # simulate a checkout
      files = checkout(identifier, true)
      files.empty?
    end

    def revisions(from_identifier, to_identifier=Time.infinity, relative_path=nil)
      checkout(to_identifier) unless uptodate?(to_identifier) # must checkout to get revisions
      parse_log(changes_command(from_identifier, to_identifier, relative_path))
    end
    
    def diff(revision_file)
      with_working_dir(@checkout_dir) do
        opts = case revision_file.status
          when /#{RevisionFile::MODIFIED}/; "#{revision_option(revision_file.previous_native_revision_identifier)} #{revision_option(revision_file.native_revision_identifier)}"
          when /#{RevisionFile::DELETED}/; "#{revision_option(revision_file.previous_native_revision_identifier)}"
          when /#{RevisionFile::ADDED}/; "#{revision_option(Time.epoch)} #{revision_option(revision_file.native_revision_identifier)}"
        end
        # IMPORTANT! CVS NT has a bug in the -N diff option
        # http://www.cvsnt.org/pipermail/cvsnt-bugs/2004-November/000786.html
        cmd = command_line("diff -Nu #{opts} #{revision_file.path}")
        Better.popen(cmd, "r", 1) do |io|
          return(yield(io))
        end
      end
    end
    
    def open(revision_file, &block)
      with_working_dir(@checkout_dir) do
        cmd = "cvs -Q update -p -r #{revision_file.native_revision_identifier} #{revision_file.path}"
        Better.popen(cmd) do |io|
          block.call io
        end
      end
    end
    
    def ls(relative_path)
      with_working_dir(@checkout_dir) do
        cmd = "cvs -Q ls #{relative_path}"
        Better.popen(cmd) do |io|
          puts io.read
        end
      end
    end

    def apply_label(label)
      cvs(@checkout_dir, "tag -c #{label}")
    end

    def trigger_mechanism
      "CVSROOT/loginfo"
    end
    
    def trigger_installed?(trigger_command, trigger_files_checkout_dir)
      loginfo_line = "#{mod} #{trigger_command}"
      regex = Regexp.new(Regexp.escape(loginfo_line))

      root_cvs = create_root_cvs(trigger_files_checkout_dir)
      begin
        root_cvs.checkout
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

    def install_trigger(trigger_command, trigger_files_checkout_dir)
      raise "mod can't be null or empty" if (mod.nil? || mod == "")

      root_cvs = create_root_cvs(trigger_files_checkout_dir)
      root_cvs.checkout
      with_working_dir(trigger_files_checkout_dir) do
        trigger_line = "#{mod} #{trigger_command}\n"
        File.open("loginfo", File::WRONLY | File::APPEND) do |file|
          file.puts(trigger_line)
        end
        begin
          root_cvs.commit("Installed trigger for CVS module '#{mod}'")
        rescue
          raise ["Didn't have permission to commit CVSROOT/loginfo.",
                "Try to manually add the following line:",
                trigger_command,
                "Finally make commit the file to the repository"]
        end
      end
    end
    
    def uninstall_trigger(trigger_command, trigger_files_checkout_dir)
      loginfo_line = "#{mod} #{trigger_command}"
      regex = Regexp.new(Regexp.escape(loginfo_line))

      root_cvs = create_root_cvs(trigger_files_checkout_dir)
      root_cvs.checkout
      loginfo_path = File.join(trigger_files_checkout_dir, "loginfo")
      File.comment_out(loginfo_path, regex, "# ")
      with_working_dir(trigger_files_checkout_dir) do
        root_cvs.commit("Uninstalled trigger for CVS mod '#{mod}'")
      end
      raise "Couldn't uninstall/commit trigger to loginfo" if trigger_installed?(trigger_command, trigger_files_checkout_dir)
    end

    def create_central
      raise "Can't create central CVS repository for #{root}" unless can_create_central?
      File.mkpath(path)
      cvs(path, "init")
    end

    def destroy_central
      if(File.exist?(path) && local?)
        FileUtils.rm_rf(path)
      else
        raise "Cannot destroy central repository. '#{path}' doesn't exist or central repo isn't local to this machine"
      end
    end
    
    def central_exists?
      if(local?)
        File.exists?("#{path}/CVSROOT/loginfo")
      else
        # don't know. assume yes.
        true
      end
    end

    def can_create_central?
      begin
        local?
      rescue
        false
      end
    end

    def supports_trigger?
      true
    end

    def checked_out?
      rootcvs = File.expand_path("#{checkout_dir}/CVS/Root")
      File.exists?(rootcvs)
    end
        
  private

    def cvs(dir, cmd, simulate=false)
      dir = PathConverter.nativepath_to_filepath(dir)
      dir = File.expand_path(dir)
      execed_command_line = command_line(cmd, password, simulate)
      with_working_dir(dir) do
        Better.popen(execed_command_line) do |stdout|
          stdout.each_line do |progress|
            yield progress if block_given?
          end
        end
      end
    end

    def parse_log(cmd, &proc)
      execed_command_line = command_line(cmd, password)
      revisions = nil
      with_working_dir(@checkout_dir) do
        Better.popen(execed_command_line) do |stdout|
          parser = CvsLogParser.new(stdout)
          parser.cvspath = path
          parser.cvsmodule = mod
          revisions = parser.parse_revisions
        end
      end
      revisions
    end

    def changes_command(from_identifier, to_identifier, relative_path)
      # https://www.cvshome.org/docs/manual/cvs-1.11.17/cvs_16.html#SEC144
      # -N => Suppress the header if no RevisionFiles are selected.
      "log #{branch_option} -N #{period_option(from_identifier, to_identifier)} #{relative_path}"
    end

    def branch_specified?
      branch && branch.strip != ""
    end

    def branch_option
      branch_specified? ? "-r#{branch}" : ""
    end

    def update_command(to_identifier)
      "update #{branch_option} -d -P -A #{revision_option(to_identifier)}"
    end

    def checkout_command(target_dir, to_identifier)
      "checkout #{branch_option} -d #{target_dir} #{revision_option(to_identifier)} #{mod}"
    end
    
    def period_option(from_identifier, to_identifier)
      if(from_identifier.nil? && to_identifier.nil?)
        ""
      else
        "-d\"#{cvsdate(from_identifier)}<#{cvsdate(to_identifier)}\" " 
      end
    end
      
    def cvsdate(time)
      return "" unless time
      # CVS wants all dates as UTC.
      time.utc.strftime("%Y-%m-%d %H:%M:%S UTC")
    end
    
    def root_with_password(password)
      result = nil
      if local?
        result = root
      elsif password && password != ""
        protocol, user, host, path = parse_cvs_root
        result = ":#{protocol}:#{user}:#{password}@#{host}:#{path}"
      else
        result = root
      end
    end
  
    def command_line(cmd, password=nil, simulate=false)
      cvs_options = simulate ? "-n" : ""
      dev_null_redirection = WIN32 ? "" : "2> /dev/null"
      "cvs -f \"-d#{root_with_password(password)}\" #{cvs_options} -q #{cmd} #{dev_null_redirection}"
    end

    def create_root_cvs(checkout_dir)
      cvs = Cvs.new(self.root, "CVSROOT", nil, self.password)
      cvs.checkout_dir = checkout_dir
      cvs
    end

    def revision_option(identifier)
      option = nil
      if(identifier.is_a?(Time))
        option = "-D\"#{cvsdate(identifier)}\""
      elsif(identifier.is_a?(String))
        option = "-r#{identifier}"
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
      parse_cvs_root[3]
    end
    
    def protocol
      parse_cvs_root[0]
    end
    
    # parses the root into tokens
    # [protocol, user, host, path]
    #
    def parse_cvs_root
      md = case
        when root =~ /^:local:/   then /^:(local):(.*)/.match(root)
        when root =~ /^:ext:/     then /^:(ext):(.*)@(.*):(.*)/.match(root)
        when root =~ /^:pserver:/ then /^:(pserver):(.*)@(.*):(.*)/.match(root)
      end
      result = case
        when root =~ /^:local:/   then [md[1], nil, nil, md[2]]
        when root =~ /^:ext:/     then md[1..4]
        when root =~ /^:pserver:/ then md[1..4]
        else ["local", nil, nil, root]
      end
    end
  end
end
