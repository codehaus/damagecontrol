require 'rscm/abstract_scm'
require 'rscm/path_converter'
require 'rscm/line_editor'

require 'fileutils'
require 'socket'
require 'pp'
require 'parsedate'
require 'stringio'

module RSCM
  # Understands operations against multiple client-workspaces
  class Perforce < AbstractSCM
    include FileUtils

    def initialize
      @clients = {}
    end

    def name
      "Perforce"
    end

    def import(dir, comment)
      with_create_client(dir) do |client|
        client.add_all(list_files)
        client.submit(comment)
      end
    end

    def checkout(checkout_dir, to_time=nil, simulate=false, &line_proc)
      client(checkout_dir).checkout(to_time, simulate, &line_proc)
    end

    def add(checkout_dir, relative_filename)
      client(checkout_dir).add(relative_filename)
    end

    def commit(checkout_dir, message, &proc)
      client(checkout_dir).submit(message, &proc)
    end

    def changesets(checkout_dir, from_time, to_time = nil, files = nil)
      client(checkout_dir).changesets(from_time, to_time, files)
    end

    def uptodate?(checkout_dir)
      client(checkout_dir).uptodate?
    end

    def edit(file)
      client_containing(file).edit(file)
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

    private
    def p4admin
      @p4admin ||= P4Admin.new
    end

    def client_containing(path)
      @clients.values.find {|client| client.contains?(path)}
    end

    def client(rootdir)
      @clients[rootdir] ||= create_client(rootdir)
    end

    def with_create_client(rootdir)
      raise "needs a block" unless block_given?
      rootdir = File.expand_path(rootdir)
      with_working_dir(rootdir) do
        client = create_client(rootdir)
        begin
          yield client
        ensure
          delete_client(client)
        end
      end
    end

    def delete_client(client)
      p4admin.delete_client(client.name)
    end

    def create_client(rootdir)
      rootdir = File.expand_path(rootdir) if rootdir =~ /\.\./
      mkdir_p(rootdir)
      p4admin.create_client(rootdir)
    end

    def list_files
      files = Dir["**/*"].delete_if{|f| File.directory?(f)}
      files.collect{|f| File.expand_path(f)}
    end
  end

  # Understands p4 administrative operations (not specific to a client)
  class P4Admin
    @@counter = 0

    def create_client(rootdir)
      name = next_name
      popen("client -i", "w+", clientspec(name, rootdir))
      P4Client.new(name, rootdir)
    end

    def delete_client(name)
      execute("client -d #{name}")
    end

    def trigger_installed?(trigger_command)
      triggers.any? {|line| line =~ /#{trigger_command}/}
    end

    def install_trigger(trigger_command)
      popen("triggers -i", "a+", triggerspec_with(trigger_command))
    end

    def uninstall_trigger(trigger_command)
      popen("triggers -i", "a+", triggerspec_without(trigger_command))
    end

    def triggerspec_with(trigger_command)
      new_trigger = " damagecontrol commit //depot/... \"#{trigger_command}\" "
      triggers + $/ + new_trigger
    end

    def triggerspec_without(trigger_command)
      triggers.reject {|line| line =~ /#{trigger_command}/}.join
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

    def popen(cmd, mode, input)
      IO.popen("p4 -p 1666 #{cmd}", mode) do |io|
        io.puts(input)
        io.close_write
        io.each_line {|line| debug(line)}
      end
    end

    def execute(cmd)
      cmd = "p4 -p 1666 #{cmd}"
      puts "> executing: #{cmd}"
      `#{cmd}`
    end

    def next_name
      "client#{@@counter += 1}"
    end
  end

  # Understands operations against a client-workspace
  class P4Client
    DATE_FORMAT = "%Y/%m/%d:%H:%M:%S"
    STATUS = { "add" => Change::ADDED, "edit" => Change::MODIFIED, "delete" => Change::DELETED }

    attr_accessor :name

    def initialize(name, rootdir)
      @name = name
      @rootdir = rootdir
    end

    def contains?(file)
      file =~ /^#{@rootdir}/
    end

    def uptodate?
      p4("sync -n").empty?
    end

    def changesets(from_time, to_time, files)
      from_time = if from_time.nil? then Time.epoch else from_time end
      to_time = if to_time.nil? then Time.infinity else to_time end
      changesets = changelists(from_time, to_time).collect {|changelist| to_changeset(changelist)}
      ChangeSets.new(changesets)
    end

    def submit(comment)
      IO.popen(p4cmd("submit -i"), "w+") do |io|
        io.puts(submitspec(comment))
        io.close_write
        io.each_line {|progress| debug progress}
      end
    end

    def edit(file)
      p4("edit #{file}")
    end

    def add(relative_path)
      add_file(@rootdir + "/" + relative_path)
    end

    def add_all(files)
      files.each {|file| add_file(file)}
    end

    def add_file(absolute_path)
      p4("add #{absolute_path}")
    end

    def checkout(scm_to_time=nil, simulate=false, &line_proc)
      p4("sync").collect {|output| $2 if output =~ /.* - (added as|updating|deleted as) #{@rootdir}\/(.*)/}
    end

    private
    def changelists(from_time, to_time)
      from = from_time.strftime(DATE_FORMAT)
      to = to_time.strftime(DATE_FORMAT)
      p4changes(from, to).collect do |line|
        P4Changelist.new(p4describe($1)) if line =~ /^Change (\d+) /
      end
    end

    def to_changeset(changelist)
      changes = changelist.files.collect do |filespec|
        change = Change.new(filespec.path, changelist.developer, changelist.message, filespec.revision, changelist.time)
        change.status = STATUS[filespec.status]
        change.previous_revision = filespec.revision - 1
        change
      end
      changeset = ChangeSet.new(changes)
      changeset.revision = changelist.number
      changeset.developer = changelist.developer
      changeset.message = changelist.message
      changeset.time = changelist.time
      changeset
    end

    def p4describe(chnum)
      p4("describe -s #{chnum}")
    end

    def p4changes(from, to)
      p4("changes //...@#{from},#{to}")
    end

    def p4(cmd)
      cmd = "#{p4cmd(cmd)}"
      puts "> executing: #{cmd}"
      output = `#{cmd}`
      puts output
      output
    end

    def p4cmd(cmd)
       "p4 -p 1666 -c #{@name} #{cmd}"
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
        p log
        log =~ /^Change (\d+) by (.*) on (.*)$/
        @number, @developer, @time = Integer($1), $2, Time.utc(*ParseDate.parsedate($3)[0..5])

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

  class LocalPerforce < Perforce
    attr_accessor :depotpath

    def initialize(repository_root_dir = nil)
      super()
      @depotpath = repository_root_dir
    end

    def create
      P4Daemon.new(@depotpath).start
    end

    class P4Daemon
      include FileUtils

      def initialize(depotpath)
        @depotpath = depotpath
      end

      def start
        if !running?
          launch
          assert_running
        end
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
        system("p4 -p 1666 admin stop")
      end

      def running?
        !`p4 -p 1666 info`.empty?
      end
    end

  end
end

module Kernel
  def p(o)
    puts "-----------------------------------------"
    puts o
    puts "-----------------------------------------"
  end

  alias old_system system
  def system(cmd)
    puts "> system: #{cmd}"
    result = old_system(cmd)
    raise "#{cmd} failed with code #{$?.to_s}" unless $? == 0
    result
  end

  def timeout(attempts=5, &proc)
    0.upto(attempts) do
      sleep 1
      return false if proc.call
    end
    true
  end

  #todo: replace with logger
  def debug(msg)
    puts msg
  end

  def assert(is_true, msg)
    raise msg unless is_true
  end

  def pause
    puts "Enter to continue"
    $stdin.getc
    puts "unpausing"
  end

end

class IO
  class << self
    alias old_popen popen
    def popen(cmd, modestring = "r", &proc)
      puts "> IO.popen: #{cmd}"
      old_popen(cmd, modestring, &proc)
    end
  end
end

class Time
  class << self
    def epoch
      Time.at(0)
    end

    def infinity
      Time.utc(2038)
    end
  end
end