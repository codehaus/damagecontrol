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
      relative_paths_to_add = to_relative(dir, files)

      with_working_dir(dir) do
        monotone("add #{relative_paths_to_add.join(' ')}")
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
        with_working_dir(checkout_dir) do
          monotone("heads") do |stdout|
            stdout.each_line do |line|
              next if (line =~ /^monotone:/)
            end
          end
        end
      end
    end

    def commit(checkout_dir, message)

    end

  protected

    # Checks out silently. Called by superclass' checkout.
    def checkout_silent(checkout_dir)
      monotone("checkout #{checkout_dir}", @branch, @key) do |stdout|
        stdout.each_line do |line|
          # TODO: checkout prints nothing to stdout - may be fixed in a future monotone...
          yield line if block_given?
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
