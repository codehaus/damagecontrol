require 'fileutils'
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

    def changesets_dir(project_name)
      "#{project_dir(project_name)}/changesets"
    end
    module_function :changesets_dir

    def changesets_rss_file(project_name)
      "#{changesets_dir(project_name)}/rss.xml"
    end
    module_function :changesets_rss_file

    def diff_file(project_name, changeset, change)
      "#{changesets_dir(project_name)}/#{changeset.id.to_s}/#{change.path}.diff"
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
      ENV['RSCM_BASE'] || "#{ENV['HOME']}/.rscm" || "#{ENV['HOMEDIR']}/.rscm"
    end
    module_function :basedir

  end
  
end