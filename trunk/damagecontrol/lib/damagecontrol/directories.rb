require 'fileutils'
require 'rscm/path_converter'
require 'rscm/abstract_scm' # for the modified Time.to_s

module DamageControl

  # This class knows about locations of various files and directories.
  #
  module Directories
    include FileUtils

    def project_names
      result = Dir["#{basedir}/*/project.yaml"].collect do |f| 
        File.basename(File.dirname(f))
      end
      result.sort
    end
    module_function :project_names
    
    def checkout_dir(project_name)
      "#{project_dir(project_name)}/checkout"
    end
    module_function :checkout_dir

    # File containing list of files *currently* being
    # checked out.
    def checkout_list_file(project_name)
      "#{project_dir(project_name)}/checkout_list.txt"
    end
    module_function :checkout_list_file

    def changeset_dir(project_name, changeset_identifier)
      "#{changesets_dir(project_name)}/#{changeset_identifier.to_s}"
    end
    module_function :changeset_dir

    def builds_dir(project_name, changeset_identifier)
      "#{changeset_dir(project_name, changeset_identifier)}/builds"
    end
    module_function :builds_dir

    def build_dirs(project_name, changeset_identifier)
      Dir["#{builds_dir(project_name, changeset_identifier)}/*"]
    end
    module_function :build_dirs
    
    # Dir for a build created at time +time+
    def build_dir(project_name, changeset_identifier, time)
      "#{builds_dir(project_name, changeset_identifier)}/#{time.to_s}"
    end
    module_function :build_dir
    
    # File containing the build command for a build created at time +time+
    def build_command_file(project_name, changeset_identifier, time)
      "#{build_dir(project_name, changeset_identifier, time)}/command"
    end
    module_function :build_command_file

    def changesets_dir(project_name)
      "#{project_dir(project_name)}/changesets"
    end
    module_function :changesets_dir

    def changesets_rss_file(project_name)
      "#{changesets_dir(project_name)}/changesets.rss"
    end
    module_function :changesets_rss_file

    def diff_file(project_name, changeset, change)
      "#{changesets_dir(project_name)}/#{changeset.identifier.to_s}/diffs/#{change.path}.diff"
    end
    module_function :diff_file

    def trigger_checkout_dir(project_name)
      "#{project_dir(project_name)}/trigger_checkout"
    end
    module_function :trigger_checkout_dir

    def project_config_file(project_name)
      "#{project_dir(project_name)}/project.yaml"
    end
    module_function :project_config_file

    def project_dir(project_name)
      "#{basedir}/#{project_name}"
    end
    module_function :project_dir

    def basedir
      if(ENV['DAMAGECONTROL_HOME'])
        ENV['DAMAGECONTROL_HOME']
      elsif(WINDOWS)
        RSCM::PathConverter.nativepath_to_filepath("#{ENV['HOMEDRIVE']}#{ENV['HOMEPATH']}/.damagecontrol").gsub(/\\/, "/")
      else
        "#{ENV['HOME']}/.damagecontrol"
      end
    end
    module_function :basedir

  end
  
end