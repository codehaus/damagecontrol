require 'rscm/line_editor'
require 'fileutils'
require 'rscm'

module RSCM
  class Monotone < AbstractSCM
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

    def initialize(db_file="MT.db", branch="", key="", passphrase="", keys_file="", server="")
      @db_file = File.expand_path(db_file)
      @branch = branch
      @key = key
      @passphrase = passphrase
      @keys_file = keys_file
      @server = server
    end

    def name
      "Monotone"
    end

    def distributed?
      true
    end

    def add(checkout_dir, relative_filename)
      with_working_dir(checkout_dir) do
        monotone("add #{relative_filename}")
      end
    end

    def create
      FileUtils.mkdir_p(File.dirname(@db_file))
      monotone("db init")
      monotone("read") do |io|
        io.write(File.open(@keys_file).read)
        io.close_write
      end
    end

    def transactional?
      true
    end

    def import(dir, message)
      dir = File.expand_path(dir)

      # post 0.17, this can be "cd dir && cmd add ."

      files = Dir["#{dir}/*"]
      relative_paths_to_add = to_relative(dir, files)

      with_working_dir(dir) do
        monotone("setup .", @branch, @key)
        monotone("add #{relative_paths_to_add.join(' ')}")
        monotone("commit --message='#{message}'", @branch, @key) do |io|
          io.puts(@passphrase)
          io.close_write
          io.read
        end
      end
    end

    def checked_out?(checkout_dir)
      File.exists?("#{checkout_dir}/MT")
    end

    def uptodate?(checkout_dir, from_identifier)
      if (!checked_out?(checkout_dir))
        false
      else
        lr = local_revision(checkout_dir)
        hr = head_revision(checkout_dir)
        lr == hr
      end
    end

    def changesets(checkout_dir, from_identifier, to_identifier=Time.infinity)
      checkout(checkout_dir, to_identifier)
      to_identifier = Time.infinity if to_identifier.nil?
      with_working_dir(checkout_dir) do
        monotone("log", @branch, @key) do |stdout|
          MonotoneLogParser.new.parse_changesets(stdout, from_identifier, to_identifier)
        end
      end
    end

    def commit(checkout_dir, message)
      with_working_dir(checkout_dir) do
        monotone("commit --message='#{message}'", @branch, @key) do |io|
          io.puts(@passphrase)
          io.close_write
          io.read
        end
      end
    end

    # http://www.venge.net/monotone/monotone.html#Hook-Reference
    def install_trigger(trigger_command, install_dir)
      if (WINDOWS)
        install_win_trigger(trigger_comand, install_dir)
      else
        install_unix_trigger(trigger_command, install_dir)
      end
    end
    
    def trigger_installed?(trigger_command, install_dir)
      File.exist?(@rcfile) if @rcfile
    end

    def uninstall_trigger(trigger_command, install_dir)
      File.delete(@rcfile) if @rcfile
      @rcfile = nil
    end

    def diff(checkout_dir, change, &block)
      checkout(checkout_dir, change.revision)
      with_working_dir(checkout_dir) do
        monotone("diff --revision=#{change.previous_revision} #{change.path}", @branch, @key) do |stdout|
          yield stdout
        end
      end
    end

  protected

    # Checks out silently. Called by superclass' checkout.
    def checkout_silent(checkout_dir, to_identifier)
      # pull from the "central" server
      monotone("pull #{@server} #{@branch}") if @server

      selector = expand_selector(to_identifier)
      checkout_dir = PathConverter.filepath_to_nativepath(checkout_dir, false)
      if checked_out?(checkout_dir)
        with_working_dir(checkout_dir) do
          monotone("update #{selector}")
        end
      else
        monotone("checkout #{checkout_dir}", @branch, @key) do |stdout|
          stdout.each_line do |line|
            # TODO: checkout prints nothing to stdout - may be fixed in a future monotone.
            # When/if it happens we may want to do a kosher implementation of checkout
            # to get yields as checkouts happen.
            yield line if block_given?
          end
        end
      end
    end

    # Administrative files that should be ignored when counting files.
    def ignore_paths
      return [/MT/, /\.mt-attrs/]
    end

  private

    def install_unix_trigger(trigger_command, install_dir)
      if File.exist?(post_commit_file)
        mode = File::APPEND|File::WRONLY
      else
        FileUtils.mkdir_p(install_dir + "/MT/")
        mode = File::CREAT|File::WRONLY
      end
      begin
        File.open(post_commit_file, mode) do |file|
          file.puts("function note_commit(new_id, certs)")
          execstr = ""
          trigger_command.split.each { |s|
            execstr += "\"#{s}\","
          } 
          execstr.chomp!(",")
          file.puts("  execute(#{execstr})")
          file.puts("end")
        end
      rescue
        raise "Didn't have permission to write to #{post_commit_file}."
      end
      
      # push to the "central" server
      monotone("push #{@server} #{@branch}") if @server
    end

    def post_commit_file
      @rcfile = "/tmp/monotone-trigger.lua"
      @rcfile
    end

    def local_revision(checkout_dir)
      local_revision = nil
      rev_file = File.expand_path("#{checkout_dir}/MT/revision")
      local_revision = File.open(rev_file).read.strip
      local_revision
    end
    
    def head_revision(checkout_dir)
      # FIXME: this will grab last head if heads are not merged.
      head_revision = nil
      monotone("heads", @branch) do |stdout|
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
    # which is too coarse grained. Dates are therefore not supported.
    def expand_selector(identifier)
      if(identifier.is_a?(Time))
        Log.warn("Time selectors are not supported for Monotone")
        ""
      else
        "i:#{identifier}"
      end
    end
  
    def monotone(monotone_cmd, branch=nil, key=nil)
      branch_opt = branch ? "--branch=\"#{branch}\"" : ""
      key_opt = key ? "--key=\"#{key}\"" : ""
      rcfile_opt = @rcfile ? "--rcfile=\"#{@rcfile}\"" : ""
      cmd = "monotone --db=\"#{@db_file}\" #{branch_opt} #{key_opt} #{rcfile_opt} #{monotone_cmd}"
      safer_popen(cmd, "r+") do |io|
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
