require 'damagecontrol/util/FileUtils'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/ProjectDirectories'
require 'damagecontrol/util/Logging'
require 'yaml'

# for default config
require 'damagecontrol/scm/NoSCM'
require 'damagecontrol/scm/NoTracker'

module DamageControl

  class ProjectAlreadyExistsError < Exception
    attr_reader :project_name
    
    def initialize(project_name)
      @project_name = project_name
    end
  end
  
  class InvalidProjectConfiguration < Exception
    attr_reader :config_content
    
    def initialize(config_content)
      @config_content = config_content
    end
  end

  class ProjectConfigRepository < ProjectDirectories
    include FileUtils
    include Logging
    
    # TODO: delete in a later release (plus the BWC stash at the bottom)
    # This will upgrade the old yamls to use new RSCM class names
    def upgrade_all
      project_names.each do |project_name|
        conf = project_config(project_name)
        modify_project_config(project_name, conf)
      end
    end

    def initialize(project_directories, public_web_url)
      @project_directories = project_directories
      @public_web_url = public_web_url
    end
    
    def project_exists?(project_name)
      File.exists?(@project_directories.project_config_file(project_name))
    end
    
    def new_project(project_name)
      raise ProjectAlreadyExistsError.new(project_name) if project_exists?(project_name)
      mkdir_p(@project_directories.project_dir(project_name))
      modify_project_config(project_name, default_project_config(project_name))
    end
    
    def default_project_config(project_name)
      # TODO - use symbols for keys?
      {"project_name" => project_name, "scm" => DamageControl::NoSCM.new, "tracking" => DamageControl::NoTracker.new}
    end

    def project_names
      @project_directories.project_names
    end
    
    # TODO: figure out whether to keep this in BHR or here!!! (prolly here)
    def project_config(project_name)
      config_map = File.open(@project_directories.project_config_file(project_name)) do |io|
        YAML::load(io)
      end
      config_map["project_name"] = project_name
      config_map
    end
    
    def clean_checkout_dir(project_name)
      rm_rf(checkout_dir(project_name))
    end
    
    def checkout_dir(project_name)
      @project_directories.checkout_dir(project_name)
    end
    
    def trigger_checkout_dir(project_name)
      @project_directories.trigger_checkout_dir(project_name)
    end
    
    def modify_project_config(project_name, config_map)
      config_map.delete("project_name")
      # remove empty pairs
      config_map.each do |key, value|
        config_map.delete(key) if value.nil? || value.to_s == ""
      end

      project_config_file_name = @project_directories.project_config_file(project_name)

      File.open(project_config_file_name, File::CREAT|File::WRONLY|File::TRUNC) do |io|
        io.puts(config_map.to_yaml)
      end
    end

    def create_build(project_name)
      build = Build.new(project_name, project_config(project_name), @public_web_url)
      build.dc_creation_time = Time.new.utc
      build.scm = create_scm(project_name)
      build.label = peek_next_build_label(project_name).to_s
      build
    end
    
    def create_scm(project_name)
      config_map = project_config(project_name)
      config_map["scm"]
    end
    
    def inc_build_label(project_name)
      number = peek_next_build_label(project_name)
      logger.info("increasing the build number for project: #{project_name} to #{number}")
      set_next_build_label(project_name, number + 1)
      number
    end
    
    def peek_next_build_label(project_name)
      return 1 if !project_exists?(project_name)
      config_map = project_config(project_name)
      next_build_label = config_map["next_build_label"] || config_map["next_build_number"] # bwc with old format
      next_build_label ? next_build_label : 1
    end
    
    def set_next_build_label(project_name, number)
      config_map = project_config(project_name)
      config_map["next_build_label"] = number
      modify_project_config(project_name, config_map)
    end

  private
      
    def next_build_label_file
      @project_directories.next_build_label_file(project_name)
    end
    
    def upgrade_removed_key(removed_key, config_map)
      config_map.delete(removed_key)
    end
    
    def upgrade_renamed_key(old_key, new_key, config_map)
      config_map[new_key] = config_map[old_key] if !config_map[new_key] && config_map[old_key]
      upgrade_removed_key(old_key, config_map)
    end

  end
  
  # Backwards compatibility for old DC configs. 

  module BWC
    def class
      super.superclass
    end
  end
  class Jira < RSCM::Tracker::JIRA
    include BWC
  end
  class RubyForgeTracker < RSCM::Tracker::RubyForge
    include BWC
  end
  class Scarab < RSCM::Tracker::Scarab
    include BWC
  end
  class SourceForgeTracker < RSCM::Tracker::SourceForge
    include BWC
  end
  class Bugzilla < RSCM::Tracker::Bugzilla
    include BWC
  end
  class CVS < RSCM::CVS
    include BWC
  end
  class SVN < RSCM::SVN
    include BWC
  end
  class ChangeSets < RSCM::ChangeSets
    include BWC
  end
  class ChangeSet < RSCM::ChangeSet
    include BWC
  end
  class Change < RSCM::Change
    include BWC
  end

end
