require 'rscm/abstract_scm'
require 'tempfile'
require 'rscm/path_converter'
require 'fileutils'

module RSCM
  class Darcs < AbstractSCM

    def initialize(dir=nil)
      @dir = File.expand_path(dir)
    end

    def name
      "Darcs"
    end

    def create
      with_working_dir(@dir) do
        IO.popen("darcs initialize") do |stdout|
          stdout.each_line do |line|
            yield line if block_given?
          end
        end
      end
    end
    
    def import(dir, message)
      ENV["EMAIL"] = "dcontrol@codehaus.org"
      FileUtils.cp_r(Dir.glob("#{dir}/*"), @dir)
      with_working_dir(@dir) do
puts "IN::::: #{@dir}"
        cmd = "darcs add --recursive ."
puts cmd
        IO.popen(cmd) do |stdout|
          stdout.each_line do |line|
            yield line if block_given?
          end
        end
puts $?
        logfile = Tempfile.new("darcs_logfile")
        logfile.print(message)
        logfile.close
        
        cmd = "darcs record --all --patch-name \"something nice\" --logfile #{PathConverter.filepath_to_nativepath(logfile.path, false)}"
puts cmd
        IO.popen(cmd) do |stdout|
          stdout.each_line do |line|
            yield line if block_given?
          end
        end
puts $?
      end
    end

    def checkout(checkout_dir) # :yield: file
      with_working_dir(File.dirname(checkout_dir)) do
cmd = "darcs get --verbose --repo-name #{File.basename(checkout_dir)} #{@dir}"
puts cmd
        IO.popen(cmd) do |stdout|
          stdout.each_line do |line|
puts line
            yield line if block_given?
          end
        end
      end
puts $?
    end
  end
end
