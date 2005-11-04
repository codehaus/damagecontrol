require 'rscm/base'
require 'rscm/path_converter'
require 'rscm/line_editor'

require 'fileutils'
require 'socket'
require 'pp'
require 'parsedate'
require 'stringio'

module RSCM
  # Perforce RSCM implementation.
  #
  # Understands operations against multiple client-workspaces
  # You need the p4/p4d executable on the PATH in order for it to work.
  #
  class Perforce < Base
    @@counter = 0

    attr_accessor :client_name
    attr_accessor :port
    attr_accessor :user
    attr_accessor :pwd
    attr_accessor :repository_root_dir

    def initialize(port = "1666", user = ENV["LOGNAME"], pwd = "", client_name = Perforce.next_client_name)
      @port, @user, @pwd, @client_name = port, user, pwd, client_name
    end

    def p4admin
      @p4admin ||= P4Admin.new(@port, @user, @pwd)
    end

    def p4client
      @p4client ||= p4admin.create_client(@checkout_dir, @client_name)
    end

    def can_create_central?
      true
    end
    
    def create_central
      raise "perforce depot can be created only from tests" unless @repository_root_dir
      @p4d = P4Daemon.new(@repository_root_dir)
      @p4d.start
    end

    def destroy_central
      @p4d.shutdown
    end

    def central_exists?
      p4admin.central_exists?
    end

    def can_create_central?
      true
    end

    def supports_trigger?
      true
    end

    def transactional?
      true
    end

    def import_central(dir, comment)
      with_create_client(dir) do |client|
        client.add_all(list_files)
        client.submit(comment)
      end
    end

    def checkout(to_identifier = nil, &proc)
      p4client.checkout(to_identifier, &proc)
    end

    def add(relative_filename)
      p4client.add(relative_filename)
    end

    def move(relative_src, relative_dest)
      p4client.move(checkout_dir, relative_src, relative_dest)
    end

    def commit(message, &proc)
      p4client.submit(message, &proc)
    end

    def revisions(from_identifier, to_identifier=Time.infinity)
      p4client.revisions(from_identifier, to_identifier)
    end

    def uptodate?(from_identifier)
      p4client.uptodate?
    end

    def edit(file)
      p4client.edit(file)
    end

    def trigger_installed?(trigger_command, trigger_files_checkout_dir)
      p4admin.trigger_installed?(trigger_command)
    end

    def install_trigger(trigger_command, damagecontrol_install_dir)
      p4admin.install_trigger(trigger_command)
    end

    def uninstall_trigger(trigger_command, trigger_files_checkout_dir)
      p4admin.uninstall_trigger(trigger_command)
    end

    def diff(revfile, &proc)
      p4client.diff(revfile, &proc)
    end

  private

    def with_create_client(rootdir)
      raise "needs a block" unless block_given?
      rootdir = File.expand_path(rootdir)
      with_working_dir(rootdir) do
        FileUtils.mkdir_p(rootdir)
        client = p4admin.create_client(rootdir, Perforce.next_client_name)
        begin
          yield client
        ensure
          delete_client(client)
        end
      end
    end

    def self.next_client_name
      "temp_client_#{@@counter += 1}"
    end

    def delete_client(client)
      p4admin.delete_client(client)
    end

    def list_files
      files = Dir["**/*"].delete_if{|f| File.directory?(f)}
      files.collect{|f| File.expand_path(f)}
    end
  end

  # Understands p4 administrative operations (not specific to a client)
  class P4Admin

    def initialize(port, user, pwd)
      @port, @user, @pwd = port, user, pwd
    end

    def create_client(rootdir, clientname)
      rootdir = File.expand_path(rootdir) if rootdir =~ /\.\./
      unless client_exists?(rootdir, clientname)
        execute_popen("client -i", "w+", clientspec(clientname, rootdir))
      end
      P4Client.new(rootdir, clientname, @port, @user, @pwd)
    end

    def client_exists?(rootdir, clientname)
      dir_regex = Regexp.new(rootdir)
      name_regex = Regexp.new(clientname)
      execute("clients").split("\n").find {|c| c =~ dir_regex && c =~ name_regex}
    end

    def delete_client(client)
      execute("client -d #{client.name}")
    end

    def trigger_installed?(trigger_command)
      triggers.any? {|line| line =~ /#{trigger_command}/}
    end

    def install_trigger(trigger_command)
      execute_popen("triggers -i", "a+", triggerspec_append(trigger_command))
    end

    def uninstall_trigger(trigger_command)
      execute_popen("triggers -i", "a+", triggerspec_remove(trigger_command))
    end

    def triggerspec_append(trigger_command)
      new_trigger = " damagecontrol commit //depot/... \"#{trigger_command}\" "
      triggers + $/ + new_trigger
    end

    def triggerspec_remove(trigger_command)
      triggers.reject {|line| line =~ /#{trigger_command}/}.join
    end

    def central_exists?
      execute("info").split.join(" ") !~ /Connect to server failed/
    end

    def clientspec(name, rootdir)
      s = StringIO.new
      s.puts "Client: #{name}"
      s.puts "Owner: #{ENV["LOGNAME"]}"
      s.puts "Host: #{ENV["HOSTNAME"]}"
      s.puts "Description: another one"
      s.puts "Root: #{rootdir}"
      s.puts "Options: noallwrite noclobber nocompress unlocked nomodtime normdir"
      s.puts "LineEnd: local"
      s.puts "View: //depot/... //#{name}/..."
      s.string
    end

    def triggers
      execute("triggers -o")
    end

    def execute_popen(cmd, mode, input)
      IO.popen(format_cmd(cmd), mode) do |io|
        io.puts(input)
        io.close_write
        io.each_line {|line| debug(line)}
      end
    end

    def execute(cmd)
      cmd = format_cmd(cmd)
      $stderr.puts "> executing: #{cmd}"
      `#{cmd}`
    end

    def format_cmd(cmd)
      "p4 -p #{@port} -u '#{@user}' -P '#{@pwd}' #{cmd} 2>&1"
    end
  end

  # Understands operations against a client-workspace
  class P4Client
    DATE_FORMAT = "%Y/%m/%d:%H:%M:%S"
    STATUS = { "add" => RevisionFile::ADDED, "edit" => RevisionFile::MODIFIED, "delete" => RevisionFile::DELETED }

    def initialize(checkout_dir, name, port, user, pwd)
      @checkout_dir, @name, @port, @user, @pwd = checkout_dir, name, port, user, pwd
    end

    def uptodate?
      p4("sync -n").empty?
    end

    def revisions(from_identifier, to_identifier)
      revisions = changelists(from_identifier, to_identifier).collect {|changelist| to_revision(changelist)}
      # We have to reverse the revisions in order to make them appear in chronological order,
      # P4 lists the newest ones first.
      Revisions.new(revisions).reverse
    end

    def name
      @name
    end

    def edit(file)
      file = File.expand_path(file)
      p4("edit #{file}")
    end

    def add(relative_path)
      add_file(rootdir + "/" + relative_path)
    end
    
    # http://www.perforce.com/perforce/doc.051/manuals/cmdref/rename.html#1040665
    def move(checkout_dir, relative_src, relative_dest)
      with_working_dir(checkout_dir) do
        absolute_src = PathConverter.filepath_to_nativepath(relative_src, true)
        absolute_dest = PathConverter.filepath_to_nativepath(relative_dest, true)
        FileUtils.mv(absolute_src, absolute_dest)
        p4("integrate #{absolute_src} #{absolute_dest}")
        p4("delete #{absolute_src}")
      end
#      p4("submit #{absolute_src}")
    end

    def add_all(files)
      files.each {|file| add_file(file)}
    end

    def submit(comment)
      IO.popen(p4cmd("submit -i"), "w+") do |io|
        io.puts(submitspec(comment))
        io.close_write
        io.each_line {|progress| debug progress}
      end
    end

    def checkout(to_identifier)
      cmd = to_identifier.nil? ? "sync" : "sync //...@#{to_identifier}"
      checked_out_files = []
      p4(cmd).collect do |output|
        #puts "output: '#{output}'"
        if(output =~ /.* - (added as|updating|deleted as) #{rootdir}[\/|\\](.*)/)
          path = $2.gsub(/\\/, "/")
          checked_out_files << path
          yield path if block_given?
        end
      end
      checked_out_files
    end

    def diff(r)
      path = File.expand_path(@checkout_dir + "/" + r.path)
      from = r.previous_native_revision_identifier
      to = r.native_revision_identifier
      cmd = p4cmd("diff2 -du #{path}@#{from} #{path}@#{to}")
      Better.popen(cmd) do |io|
        return(yield(io))
      end
    end

  private

    def rootdir
      unless @rootdir
        p4("info") =~ /Client root: (.+)/
        @rootdir = $1
      end
      @rootdir
    end

    def add_file(absolute_path)
      absolute_path = PathConverter.filepath_to_nativepath(absolute_path, true)
      p4("add #{absolute_path}")
    end

    def changelists(from_identifier, to_identifier)
      p4changes(from_identifier, to_identifier).collect do |line|
        if line =~ /^Change (\d+) /
          log = p4describe($1)
          P4Changelist.new(log) unless log == ""
        end
      end
    end

    def to_revision(changelist)
      return nil if changelist.nil? # Ugly, but it seems to be nil some times on windows.
      changes = changelist.files.collect do |filespec|
        change = RevisionFile.new(filespec.path, changelist.developer, changelist.message, filespec.revision, changelist.time)
        change.status = STATUS[filespec.status]
        change.previous_native_revision_identifier = filespec.revision - 1
        change
      end
      revision = Revision.new(changes)
      revision.identifier =  changelist.number
      revision.developer = changelist.developer
      revision.message = changelist.message
      revision.time = changelist.time
      revision
    end

    def p4changes(from_identifier, to_identifier)
      from = p4timespec(from_identifier, Time.epoch)
      to = p4timespec(to_identifier, Time.infinity)
      $stderr.puts "in p4changes translated #{from_identifier},#{to_identifier} to #{from},#{to}"
      p4("changes //...@#{from},#{to}")
    end

    def p4timespec(identifier, default)
      identifier = default if identifier.nil?
      if identifier.is_a?(Time)
        identifier = Time.epoch if identifier < Time.epoch
        (identifier+1).strftime(DATE_FORMAT)
      else
        "#{identifier + 1}"
      end
    end

    def p4describe(chnum)
      p4("describe -s #{chnum}")
    end

    def p4(cmd)
      cmd = "#{p4cmd(cmd)}"
      $stderr.puts "> executing: #{cmd}"
      output = `#{cmd}`
      #puts output
      output
    end

    def p4cmd(cmd)
      "p4 -p #{@port} -c '#{@name}' -u '#{@user}' -P '#{@pwd}' #{cmd}"
    end

    def submitspec(comment)
      s = StringIO.new
      s.puts "Change: new"
      s.puts "Client: #{@name}"
      s.puts "Description: #{comment.gsub(/\n/, "\n\t")}"
      s.puts "Files: "
      p4("opened").each do |line|
        if line =~ /^(.+)#\d+ - (\w+) /
          status, revision = $1, $2
          s.puts "\t#{status}       # #{revision}"
        end
      end
      s.string
    end

    FileSpec = Struct.new(:path, :revision, :status)

    class P4Changelist
      attr_reader :number, :developer, :message, :time, :files

      def initialize(log)
        debug log
        if(log =~ /^Change (\d+) by (.*) on (.*)$/)
          #@number, @developer, @time = $1.to_i, $2, Time.utc(*ParseDate.parsedate($3)[0..5])
          @number, @developer, @time = $1.to_i, $2, Time.utc(*ParseDate.parsedate($3))
        else
          raise "Bad log format: '#{log}'"
        end

        if log =~ /Change (.*)\n\n(.*)\n\nAffected/m
          @message = $2.strip.gsub(/\n\t/, "\n")
        end

        @files = []
        log.each do |line|
          if line =~ /^\.\.\. \/\/depot\/(.+)#(\d+) (.+)/
            files << FileSpec.new($1, Integer($2), $3)
          end
        end
      end
    end
  end

  class P4Daemon
    include FileUtils

    def initialize(depotpath)
      @depotpath = depotpath
    end

    def start
      launch
      assert_running
    end

    def assert_running
      raise "p4d did not start properly" if timeout(10) { running? }
    end

    def launch
      fork do
        mkdir_p(@depotpath)
        cd(@depotpath)
        debug "starting p4 server"
        exec("p4d")
      end
      at_exit { shutdown }
    end

    def shutdown
      `p4 -p 1666 admin stop` if running?
    end

    def running?
      `p4 -p 1666 info 2>&1`!~ /Connect to server failed/
    end
  end
end

module Kernel

  # TODO: use Ruby's built-in timeout? (require 'timeout')
  def timeout(attempts=5, &proc)
    0.upto(attempts) do
      sleep 1
      return false if proc.call
    end
    true
  end

  #todo: replace with logger
  def debug(msg)
    #puts msg
  end

end
