require 'damagecontrol/util/FileUtils'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/ProjectDirectories'
require 'yaml'

# for default config
require 'damagecontrol/scm/NoSCM'

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
      {"project_name" => project_name, "scm" => DamageControl::NoSCM.new}
    end

    def project_names
      @project_directories.project_names
    end
    
    def project_config(project_name)
      config_map = File.open(@project_directories.project_config_file(project_name)) do |io|
        parse_project_config(io.gets(nil))
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
    
    def log_dir(project_name)
      @project_directories.log_dir(project_name)
    end
    
    def modify_project_config(project_name, config_map)
raise "DOH" unless project_name
      config_map.delete("project_name")
      # remove empty pairs
      config_map.each do |key, value|
        config_map.delete(key) if value.nil? || value.to_s == ""
      end

      project_config_file_name = @project_directories.project_config_file(project_name)

puts "Modifying config for #{project_name} -> #{project_config_file_name}"

      File.open(project_config_file_name, File::CREAT|File::WRONLY|File::TRUNC) do |io|
        io.puts(config_map.to_yaml)
      end
    end

    def create_build(project_name)
      build = Build.new(project_name, project_config(project_name))
      build.dc_creation_time = Time.new.utc
      ymdHMS = build.dc_creation_time.ymdHMS
      build.url = "#{ensure_trailing_slash(@public_web_url)}project/#{build.project_name}?dc_creation_time=#{ymdHMS}"
      build.scm = create_scm(project_name)
      build.potential_label = peek_next_build_number(project_name).to_s
      build.log_file = "#{log_dir(project_name)}/#{ymdHMS}.log"
      build.error_log_file = "#{log_dir(project_name)}/#{ymdHMS}-error.log"
      build.xml_log_file = "#{log_dir(project_name)}/#{ymdHMS}.xml"
      build.archive_dir = @project_directories.archive_dir(project_name, ymdHMS)
      build
    end
    
    def create_scm(project_name)
      config_map = project_config(project_name)
      config_map["scm"]
    end
    
    def next_build_number_file
      @project_directories.next_build_number_file(project_name)
    end
    
    def next_build_number(project_name)
      number = peek_next_build_number(project_name)
      set_next_build_number(project_name, number + 1)
      number
    end
    
    def peek_next_build_number(project_name)
      return 1 if !project_exists?(project_name)
      config_map = project_config(project_name)
      config_map["next_build_number"] ? config_map["next_build_number"] : 1
    end
    
    def set_next_build_number(project_name, number)
      config_map = project_config(project_name)
      config_map["next_build_number"] = number
      modify_project_config(project_name, config_map)
    end

  private
      
    def upgrade_removed_key(removed_key, config_map)
      config_map.delete(removed_key)
    end
    
    def upgrade_renamed_key(old_key, new_key, config_map)
      config_map[new_key] = config_map[old_key] if !config_map[new_key] && config_map[old_key]
      upgrade_removed_key(old_key, config_map)
    end

    def parse_project_config(config_content)
      config = YAML::load(config_content)
      raise InvalidProjectConfiguration.new(config_content) unless config.is_a? Hash
      config
    end
    
  end
  
end
