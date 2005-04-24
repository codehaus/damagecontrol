require 'tempfile'
require 'fileutils'
require 'rscm'

module RSCM
  class Darcs < AbstractSCM
    #register self

    ann :description => "Directory"
    attr_accessor :dir

    def initialize(dir=".")
      @dir = File.expand_path(dir)
    end

    def name
      "Darcs"
    end

    def can_create_central?
      true
    end

    def create_central
      with_working_dir(@dir) do
        darcs("initialize")
      end
    end
    
    def import_central(dir, message)
      ENV["EMAIL"] = "dcontrol@codehaus.org"
      FileUtils.cp_r(Dir.glob("#{dir}/*"), @dir)
      with_working_dir(@dir) do
        darcs("add --recursive .")
        
        logfile = Tempfile.new("darcs_logfile")
        logfile.print("something nice\n")
        logfile.print(message + "\n")
        logfile.close
        
        darcs("record --all --logfile #{PathConverter.filepath_to_nativepath(logfile.path, false)}")
      end
    end

    def commit(message)
      logfile = Tempfile.new("darcs_logfile")
      logfile.print("something nice\n")
      logfile.print(message + "\n")
      logfile.close

      with_working_dir(@checkout_dir) do
        darcs("record --all --logfile #{PathConverter.filepath_to_nativepath(logfile.path, false)}")
      end
    end

    def add(relative_filename)
      with_working_dir(@checkout_dir) do
        darcs("add #{relative_filename}")
      end
    end

    def checked_out?
      File.exists?("#{@checkout_dir}/_darcs")
    end

    def uptodate?(from_identifier)
      if (!checked_out?(@checkout_dir))
        false
      else
        with_working_dir(@checkout_dir) do
          darcs("pull --dry-run #{@dir}") do |io|
            io.each_line do |line|
              if (line =~ /No remote changes to pull in!/)
                true
              else
                false
              end
            end
          end
        end
      end
    end

    def revisions(from_identifier, to_identifier=Time.infinity)
      from_identifier = Time.epoch if from_identifier.nil?
      to_identifier = Time.infinity if to_identifier.nil?
      with_working_dir(@checkout_dir) do
        darcs("changes --summary --xml-output") do |stdout|
          DarcsLogParser.new.parse_revisions(stdout, from_identifier, to_identifier)
        end
      end
    end
  
  protected

    def checkout_silent(to_identifier) # :yield: file
      with_working_dir(File.dirname(checkout_dir)) do
        darcs("get --repo-name #{File.basename(checkout_dir)} #{@dir}")
      end
    end

    def ignore_paths
      return [/_darcs/]
    end

  private

    def darcs(darcs_cmd)
      cmd = "darcs #{darcs_cmd}"

      safer_popen(cmd, "r+") do |io|
        if(block_given?)
          return(yield(io))
        else
          io.read
        end
      end
    end
  end
end
