require 'fileutils'
module RSCM

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

    # TODO: we should store the diff file on disk instead,
    # and generate individual sub-htmls on the fly for specific
    # diffs inside it, using hashes (md5) to identify individual diffs
    # witin the diff file. RSS should maybe be generated on the fly
    # too if we want to have colour html in them (not sure if we want that tho).
    def diff_file(project_name, changeset, change)
      "#{changesets_dir(project_name)}/#{changeset.id}/#{change.path}.diff"
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
      @@basedir ||= ENV["RSCM_BASE"] || File.expand_path(File.dirname(__FILE__) + "/../../target/work")
    end
    module_function :basedir

  end
  
end