require 'rscm/abstract_scm'
require 'fileutils'

module RSCM
  class Monotone < AbstractSCM
    def initialize(db_file=nil, branch=nil, key=nil, passphrase=nil, keys_file=nil)
      @db_file = File.expand_path(db_file) if db_file
      @branch = branch
      @key = key
      @passphrase = passphrase
      @keys_file = keys_file
    end

    def name
      "Monotone"
    end

    def create
      FileUtils.mkdir_p(File.dirname(@db_file))
      monotone("db init")
      monotone("read") do |io|
        io.write(File.open(@keys_file).read)
        io.close_write
      end
    end

    def import(dir, message)
      dir = File.expand_path(dir)

      # post 0.17, this can be "cd dir && cmd add ."

      files = Dir["#{dir}/*"]
      dirs = files.find_all {|f| File.directory?(f)}
      relative_dirs = dirs.collect{|p| p[dir.length+1..-1]}

      add_cmd = "monotone --db=\"#{@db_file}\" add #{relative_dirs.join(' ')}"
      commit_cmd = "monotone --db=\"#{@db_file}\" --branch=\"#{@branch}\" --key=\"#{@key}\" commit '#{message}'"

      with_working_dir(dir) do
        monotone("add #{relative_dirs.join(' ')}")
        monotone("commit '#{message}'", @branch, @key) do |io|
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
      end
    end

    def checkout(checkout_dir)
      checkout_dir = PathConverter.filepath_to_nativepath(checkout_dir, false)
      mkdir_p(checkout_dir)
      checked_out_files = []
      if (checked_out?(checkout_dir))
        # update
      else
        monotone("checkout #{checkout_dir}", @branch, @key) do |stdout|
          stdout.each_line do |line|
# FIXME: nothing is coming out here....
puts "LINE: #{line}"
            yield line if block_given?
          end
        end
      end
    end
    
  private
  
    def monotone(monotone_cmd, branch=nil, key=nil)
      branch_opt = branch ? "--branch=\"#{branch}\"" : ""
      key_opt = key ? "--key=\"#{key}\"" : ""
      cmd = "monotone --db=\"#{@db_file}\" #{branch_opt} #{key_opt} #{monotone_cmd}"
puts "COMMAND: #{cmd}"
      safer_popen(cmd, "r+") do |io|
        if(block_given?)
          return(yield(io))
        else
          # just read stdout so we can exit
          io.read
        end
      end
    end
  
  end
end
