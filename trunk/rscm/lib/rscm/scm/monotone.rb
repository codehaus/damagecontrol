require 'rscm/line_editor'
require 'fileutils'
require 'rscm'

module RSCM
  class Monotone < Base
    register self

    ann :description => "Database file"
    attr_accessor :db_file

    ann :description => "Branch"
    attr_accessor :branch

    ann :description => "Key"
    attr_accessor :key

    ann :description => "Passphrase"
    attr_accessor :passphrase

    ann :description => "Keys file"
    attr_accessor :keys_file

    ann :description => "Server"
    attr_accessor :server

    def initialize(branch=nil, key=nil, passphrase=nil, keys_file=nil, server=nil, central_checkout_dir=nil)
      @branch = branch
      @key = key
      @passphrase = passphrase
      @keys_file = keys_file
      @server = server
      @central_checkout_dir = File.expand_path(central_checkout_dir) unless central_checkout_dir.nil?
    end

    def add(relative_filename)
      db = db(@checkout_dir)
      with_working_dir(@checkout_dir) do
        monotone("add #{relative_filename}", db)
      end
    end

    def can_create_central?
      @server == "localhost" && !@central_checkout_dir.nil?
    end
    
    def central_exists?
      @central_checkout_dir && @serve_pid
    end

    def create_central
      init(@central_checkout_dir)
      # create empty working copy
      dir = PathConverter.filepath_to_nativepath(@central_checkout_dir, false)
      # set up a working copy
      monotone("setup #{dir}")
      start_serve
    end
    
    def start_serve
      mode = File::CREAT|File::WRONLY
      if File.exist?(rcfile)
        mode = File::APPEND|File::WRONLY
      end

      begin
        File.open(rcfile, mode) do |file|
          file.puts("function get_netsync_anonymous_read_permitted(collection)")
          file.puts("  return true")
          file.puts("end")
        end
      rescue => e
        puts e.message
        puts e.backtrace.join("\n")
        raise "Didn't have permission to write to #{rcfile}."
      end

      @serve_pid = fork do
        #Signal.trap("HUP") { puts "Monotone server shutting down..."; exit }
        monotone("serve --rcfile=\"#{rcfile}\" #{@server} #{@branch}", db(@central_checkout_dir)) do |io|
          puts "PASSPHRASE: #{@passphrase}"
          io.puts(@passphrase)
          io.close_write
        end
      end
      Process.detach(@serve_pid)
    end
    
    def stop_serve
      Process.kill("HUP", @serve_pid) if @serve_pid
      Process.waitpid2(@serve_pid) if @serve_pid
      @serve_pid = nil
    end
    
    def destroy_central
      stop_serve
      FileUtils.rm_rf(@central_checkout_dir) if File.exist?(@central_checkout_dir)
      FileUtils.rm(db(@central_checkout_dir)) if File.exist?(db(@central_checkout_dir))
      puts "Destroyed Monotone server"
    end
    
    def transactional?
      true
    end

    def import_central(dir, message)
      cp_r(Dir["#{dir}/*"], @central_checkout_dir)
      with_working_dir(@central_checkout_dir) do
        monotone("add .")
        commit_in_dir(message, @central_checkout_dir)
      end
    end

    def checked_out?
      mt = File.expand_path("#{@checkout_dir}/MT")
      File.exists?(mt)
    end

    def uptodate?(identifier=nil)
      if (!checked_out?)
        false
      else
        pull

        rev = identifier ? identifier : head_revision
        local_revision == rev
      end
    end

    def revisions(from_identifier, to_identifier=Time.infinity)
      checkout(to_identifier)
      to_identifier = Time.infinity if to_identifier.nil?
      with_working_dir(checkout_dir) do
        monotone("log") do |stdout|
          MonotoneLogParser.new.parse_revisions(stdout, from_identifier, to_identifier)
        end
      end
    end

    def commit(message)
      commit_in_dir(message, @checkout_dir)
      with_working_dir(@checkout_dir) do
        monotone("push #{@server} #{@branch}") do |io|
          io.puts(@passphrase)
          io.close_write
          io.read
        end
      end
    end

    def supports_trigger?
      true
    end

    # http://www.venge.net/monotone/monotone.html#Hook-Reference
    def install_trigger(trigger_command, install_dir)
      stop_serve
      if (WINDOWS)
        install_win_trigger(trigger_comand, install_dir)
      else
        install_unix_trigger(trigger_command, install_dir)
      end
      start_serve
    end
    
    def trigger_installed?(trigger_command, install_dir)
      File.exist?(rcfile)
    end

    def uninstall_trigger(trigger_command, install_dir)
      stop_serve
      File.delete(rcfile)
      start_serve
    end

    def diff(change, &block)
      checkout(change.revision)
      with_working_dir(@checkout_dir) do
        monotone("diff --revision=#{change.previous_native_revision_identifier} #{change.path}") do |stdout|
          yield stdout
        end
      end
    end
    
  protected

    # Checks out silently. Called by superclass' checkout.
    def checkout_silent(to_identifier)
      # raise "Monotone doesn't support checkout to time. Please use identifiers instead." if to_identifier.is_a?(Time)
      db_file = db(@checkout_dir)
      if(!File.exist?(db_file))
        init(@checkout_dir)
      end

      pull
      checked_out = checked_out?

      with_working_dir(@checkout_dir) do
        monotone("checkout .", db_file, @branch) unless checked_out

        selector = expand_selector(to_identifier)
        monotone("update #{selector}", db_file)
      end
    end

    # Administrative files that should be ignored when counting files.
    def ignore_paths
      return [/MT/, /\.mt-attrs/]
    end

  private

    def commit_in_dir(message, dir)
      db_file = db(dir)
      with_working_dir(dir) do
        monotone("commit --message='#{message}'", db_file, @branch, @key) do |io|
          io.puts(@passphrase)
          io.close_write
          io.read
        end
      end
    end

    def pull
      db_file = db(@checkout_dir)
      with_working_dir(@checkout_dir) do
        # pull from the "central" server
        if(@server)
          monotone("pull #{@server} #{@branch}", db_file) do |io|
            io.puts(@passphrase)
            io.close_write
            io.read
          end
        end
      end
    end

    def db(checkout_dir)
      PathConverter.filepath_to_nativepath(checkout_dir + ".db", false)
    end

    # Initialises a monotone database
    #
    def init(dir)
      dir = File.expand_path(dir)
      db_file = db(dir)
      raise "Database #{db_file} already exists" if File.exist?(db_file)
      FileUtils.mkdir_p(File.dirname(db_file))
      # create database
      monotone("db init", db_file)
      # TODO: do a genkey
      monotone("read", db_file) do |io|
        io.write(File.open(@keys_file).read)
        io.close_write
      end
    end

    def install_unix_trigger(trigger_command, install_dir)
      mode = File::CREAT|File::WRONLY
      if File.exist?(rcfile)
        mode = File::APPEND|File::WRONLY
      end

      begin
        File.open(rcfile, mode) do |file|
          file.puts("function note_commit(new_id, certs)")
          execstr = "\"" + trigger_command.split.join("\",\"") + "\""
          file.puts("  execute(#{execstr})")
          file.puts("end")
        end
      rescue => e
        puts e.message
        puts e.backtrace.join("\n")
        raise "Didn't have permission to write to #{rcfile}."
      end
      
      # push to the "central" server
#      monotone("push #{@server} #{@branch}", db(@central_checkout_dir))
    end

    def rcfile
      "#{@central_checkout_dir}/MT/monotonerc"
    end

    def local_revision
      local_revision = nil
      rev_file = File.expand_path("#{checkout_dir}/MT/revision")
      local_revision = File.open(rev_file).read.strip
      local_revision
    end
    
    def head_revision
      # FIXME: this will grab last head if heads are not merged.
      head_revision = nil
      monotone("heads", db(@checkout_dir), @branch) do |stdout|
        stdout.each_line do |line|
          next if (line =~ /^monotone:/)
          head_revision = line.split(" ")[0]
        end
      end
      head_revision
    end

    # See http://www.venge.net/monotone/monotone.html#Selectors
    # Also see docs for expand_selector in the same document
    # Dates are formatted with strftime-style %F, which is of style 2005-28-02,
    # which is very coarse grained. Date identifiers are therefore discouraged.
    def expand_selector(identifier)
      if(identifier.is_a?(Time))
        # Won't work:
        # "d:#{identifier.strftime('%Y-%m-%d')}"
        ""
      else
        "i:#{identifier}"
      end
    end
  
    def monotone(monotone_cmd, db_file=nil, branch=nil, key=nil)
      db_opt = db_file ? "--db=\"#{db_file}\"" : ""
      branch_opt = branch ? "--branch=\"#{branch}\"" : ""
      key_opt = key ? "--key=\"#{key}\"" : ""
      rcfile_opt = @rcfile ? "--rcfile=\"#{@rcfile}\"" : ""
      cmd = "monotone #{db_opt} #{branch_opt} #{key_opt} #{rcfile_opt} #{monotone_cmd}"
      Better.popen(cmd, "r+") do |io|
        if(block_given?)
          return(yield(io))
        else
          # just read stdout so we can exit
          io.read
        end
      end
    end

    def monotone_date(time)
      return nil unless time
      time.utc.strftime("%Y-%m-%dT%H:%M:%S")
    end
    
  end
end
