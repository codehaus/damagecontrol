require 'damagecontrol/util/FileUtils'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/ProjectDirectories'
require 'yaml'

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
    
    attr_reader :project_directories
    attr_reader :public_web_url
    
    def initialize(project_directories, public_web_url)
      @project_directories = project_directories
      @public_web_url = public_web_url
    end
    
    def project_exists?(project_name)
      File.exists?(project_directories.project_config_file(project_name))
    end
    
    def new_project(project_name)
      raise ProjectAlreadyExistsError.new(project_name) if project_exists?(project_name)
      mkdir_p(project_directories.project_dir(project_name))
      modify_project_config(project_name, {})
    end
    
    def project_names
      project_directories.project_names
    end
    
    def project_config(project_name)
      File.open(project_directories.project_config_file(project_name)) do |io|
        parse_project_config(io.gets(nil))
      end
    end
    
    def checkout_dir(project_name)
      project_directories.checkout_dir(project_name)
    end
    
    def modify_project_config(project_name, config_map)
      config_map["project_name"] = project_name
      # remove empty pairs
      config_map.each do |key, value|
        config_map.delete(key) if value.nil? || value.to_s == ""
      end
      
      File.open(project_directories.project_config_file(project_name), File::CREAT|File::WRONLY|File::TRUNC) do |io|
        io.puts(config_map.to_yaml)
      end
    end

    def create_build(project_name, timestamp)
      build = Build.new(project_name, timestamp, project_config(project_name))
      build.url = "#{public_web_url}/project?action=build_details&project_name=#{build.project_name}&timestamp=#{build.timestamp}"
      build
    end

  private

    def parse_project_config(config_content)
      config = YAML::load(config_content)
      raise InvalidProjectConfiguration.new(config_content) unless config.is_a? Hash
      config
    end
    
  end
  
end