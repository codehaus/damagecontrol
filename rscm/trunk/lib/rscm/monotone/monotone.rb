require 'rscm/abstract_scm'
require 'fileutils'

module RSCM
  class Monotone < AbstractSCM
    def initialize(db_file=nil, branch=nil)
      @db_file = File.expand_path(db_file) unless @db_file
      @branch = branch
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

      to_add = Dir["#{dir}/**/*"].collect{|p| p[dir.length+1..-1]}
      
      cmd = "monotone --db=\"#{@db_file}\" add #{to_add.join(' ')}"

      puts "IMPORTING: #{cmd}"
      safer_popen(cmd) do |stdout|
        stdout.each_line do |line|
          yield line if block_given?
        end
      end

#      with_working_dir(dir) do
#        Dir.chdir(dir) do
#          Dir.glob("*") do |to_add|
#          end
#        end
#        
#        cmd = "monotone --db=\"#{@db_file}\" --branch=\"#{@branch}\" commit '#{message}'"
#        safer_popen(cmd) do |stdout|
#          stdout.each_line do |line|
#            yield line if block_given?
#          end
#        end
#      end
    end

    def checkout(checkout_dir)

    end
  end
end
