require 'rscm/abstract_scm'
require 'fileutils'

module RSCM
  class Monotone < AbstractSCM
    def initialize(db_file=nil, branch=nil, key=nil)
      @db_file = File.expand_path(db_file) if db_file
      @branch = branch
      @key = key
    end

    def name
      "Monotone"
    end

    def create
      FileUtils.mkdir_p(File.dirname(@db_file))
      cmd = "monotone --db=\"#{@db_file}\" db init"
      puts "*** Command: #{cmd}"
      safer_popen(cmd) {|io| io.read}
    end

    def import(dir, message)
      dir = File.expand_path(dir)

      # post 0.17, this can be "cd dir && cmd add ."

      files = Dir["#{dir}/*"]
      dirs = files.find_all {|f| File.directory?(f)}
      relative_dirs = dirs.collect{|p| p[dir.length+1..-1]}
puts
puts relative_dirs.join("\n")
puts

      add_cmd = "monotone --db=\"#{@db_file}\" add #{relative_dirs.join(' ')}"
      commit_cmd = "monotone --db=\"#{@db_file}\" --branch=\"#{@branch}\" --key=\"#{@key}\" commit '#{message}'"

      puts "IMPORTING: #{add_cmd}"
      with_working_dir(dir) do
        safer_popen(add_cmd) do |stdout|
          stdout.each_line do |line|
            yield line if block_given?
          end
        end
        safer_popen(commit_cmd) do |stdout|
          stdout.each_line do |line|
            yield line if block_given?
          end
        end
      end
    end

    def checkout(checkout_dir)

    end
  end
end
