require 'rscm/abstract_scm'
require 'fileutils'

module RSCM
  class Monotone < AbstractSCM
    def initialize(dir=nil, db_file=nil, branch=nil)
      @db_file = db_file
      @branch = branch
      @repo_dir = dir
    end

    def name
      "Monotone"
    end

    def create
      with_working_dir(@repo_dir) do
        cmd = "monotone --db=\"#{@db_file}\" db init"
        puts "*** Working Dir: " + @repo_dir
        puts "*** Command: " + cmd
        safer_popen(cmd) do |stdout|
          stdout.each_line do |line|
            yield line if block_given?
          end
        end
      end
    end

    def import(dir, message)
      # post 0.17, this can be "cd dir && cmd add ."
      with_working_dir(@repo_dir) do
        cmd = "monotone --db=\"#{@db_file}\" add "
        Dir.chdir(dir) do
          Dir.glob("*") do |to_add|
            safer_popen(cmd + to_add) do |stdout|
              stdout.each_line do |line|
                yield line if block_given?
              end
            end
          end
        end
        
        cmd = "monotone --db=\"#{@db_file}\" --branch=\"#{@branch}\" commit '#{message}'"
        safer_popen(cmd) do |stdout|
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
