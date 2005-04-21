require 'rscm/abstract_scm'
require 'rscm/path_converter'
require 'rscm/line_editor'

require 'fileutils'
require 'socket'
require 'pp'
require 'parsedate'
require 'stringio'


module RSCM
  # RSCM implementation for Perforce.
  #
  # Understands operations against multiple client-workspaces
  # You need the p4/p4d executable on the PATH in order for it to work.
  #
  class Perforce < AbstractSCM
    register self

    include FileUtils

    ann :description => "P4CLIENT", :tip => "The Perforce client workspace name"
    attr_accessor :client_name

    ann :description => "P4PORT", :tip => "The host where the Perforce server is available e.g. 10.12.1.55:1666"
    attr_accessor :port

    ann :description => "P4USER", :tip => "Perforce username"
    attr_accessor :user

    ann :description => "P4PASSWD", :tip => "Perforce password"
    attr_accessor :pwd

    def initialize(client_name = "", port = "", user = "", pwd = "")
      @client_name, @port, @user, @pwd = client_name, port, user, pwd
    end

    def can_create_central?
      true
    end
    
    def create_central
    end

    def name
      "Perforce"
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
      client.checkout(to_identifier, &proc)
    end

    def add(relative_filename)
      client.add(relative_filename)
    end

    def commit(message, &proc)
      client.submit(message, &proc)
    end

    def changesets(from_identifier, to_identifier=Time.infinity)
      client.changesets(from_identifier, to_identifier)
    end

    def uptodate?(from_identifier)
      client.uptodate?
    end

    def edit(file)
      client.edit(file)
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

    def client
      @p4 ||= P4Client.new(@client_name, @port, @user, @pwd)
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
      p4admin.delete_client(client)
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
      P4Client.new(name)
    end

    def delete_client(client)
      execute("client -d #{client.name}")
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
    PERFORCE_EPOCH = Time.utc(1970, 1, 1, 6, 0, 1)  #perforce doesn't like Time.utc(1970)

    def initialize(name, port = "1666", user = ENV["LOGNAME"], pwd = "")
      @name, @port, @user, @pwd = name, port, user, pwd
    end

    def uptodate?
      p4("sync -n").empty?
    end

    def changesets(from_identifier, to_identifier)
      changesets = changelists(from_identifier, to_identifier).collect {|changelist| to_changeset(changelist)}
      ChangeSets.new(changesets)
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
        puts "output: '#{output}'"
        if(output =~ /.* - (added as|updating|deleted as) #{rootdir}[\/|\\](.*)/)
          path = $2.gsub(/\\/, "/")
          checked_out_files << path
          yield path if block_given?
        end
      end
      checked_out_files
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

    def to_changeset(changelist)
      return nil if changelist.nil? # Ugly, but it seems to be nil some times on windows.
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

    def p4changes(from_identifier, to_identifier)
      puts "p4changes #{from_identifier}, #{to_identifier}"
      from = p4timespec(from_identifier,PERFORCE_EPOCH)
      to = p4timespec(to_identifier,Time.infinity)
      p4("changes //...#{from},#{to}")
    end

    def p4timespec(identifier, default)
      if identifier.nil? 
          default
      elsif identifier.is_a?(Time)
          identifier.strftime(DATE_FORMAT)
      else
          "@#{identifier}"
      end
    end

    def p4describe(chnum)
      p4("describe -s #{chnum}")
    end

    def p4(cmd)
      cmd = "#{p4cmd(cmd)}"
      puts "> executing: #{cmd}"
      output = `#{cmd}`
      puts output
      output
    end

    def p4cmd(cmd)
      passwd = @pwd.strip.empty? ? "" : "-P #{@pwd}"
      "p4 -p #{@port} -c #{@name} -u #{@user} #{passwd} #{cmd}"
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
#          @number, @developer, @time = $1.to_i, $2, Time.utc(*ParseDate.parsedate($3)[0..5])
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
    puts msg
  end

end
