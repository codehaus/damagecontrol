require 'damagecontrol/util/FileUtils'
require 'pebbles/TimeUtils'

module DamageControl

  # This class knows about locations of various files and directories.
  # Other classes depending on this class can be easily tested by mocking
  # this class (and let the mock point to files/dirs in the test directory)
  #
  class ProjectDirectories
    def initialize(basedir)
      @basedir = File.expand_path(basedir)
    end
    
    def project_names
      result = Dir["#{@basedir}/*/conf.yaml"].collect do |f| 
        File.basename(File.dirname(f))
      end
      result.sort
    end
    
    def checkout_dir(project_name)
      "#{project_dir(project_name)}/checkout"
    end

    def trigger_checkout_dir(project_name)
      "#{project_dir(project_name)}/trigger_checkout"
    end

    def stdout_file(project_name, dc_creation_time)
      "#{build_dir(project_name, dc_creation_time)}/stdout.log"
    end

    def stderr_file(project_name, dc_creation_time)
      "#{build_dir(project_name, dc_creation_time)}/stderr.log"
    end

    def xml_log_file(project_name, dc_creation_time)
      "#{build_dir(project_name, dc_creation_time)}/log.xml"
    end

    def archive_dir(project_name, dc_creation_time)
      "#{build_dir(project_name, dc_creation_time)}/archive"
    end

    def project_dir(project_name)
      "#{@basedir}/#{project_name}"
    end

    def builds_dir(project_name)
      "#{project_dir(project_name)}/build"
    end

    def build_dirs(project_name)
      Dir["#{builds_dir(project_name)}/[0-9]*"].sort
    end

    def build_dir(project_name, dc_creation_time)
      "#{builds_dir(project_name)}/#{dc_creation_time.ymdHMS}"
    end

    def rss_file(project_name)
      "#{builds_dir(project_name)}/rss.xml"
    end

    def project_config_file(project_name)
      "#{project_dir(project_name)}/conf.yaml"
    end    

  end
  
end