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
    
    def initialize(project_directories)
      @project_directories = project_directories
    end
    
    def project_exists?(project_name)
      File.exists?(project_directories.project_config_file(project_name))
    end
    
    def new_project(project_name)
      raise ProjectAlreadyExistsError.new(project_name) if project_exists?(project_name)
      mkdir_p(project_directories.project_dir(project_name))
      modify_project_config(project_name, {})
    end
    
    def parse_project_config(config_content)
      eof_stripped = ""
      config_content.each do |line|
        if(line.chomp == "...")
          break
        else
          # Workaround for new Ruby symbol semantics in YAML.
          # A String that starts with a colon will be converted
          # to a symbol, which is not what we want.
          # Therefore, replace the offending ":"s with "_" and take it out afterwards.
          line.gsub!(/:pserver:/, "_pserver:")
          line.gsub!(/:local:/, "_local:")
          line.gsub!(/:ext:/, "_ext:")

          eof_stripped << line
        end
      end
      config = YAML::load(eof_stripped)
      raise InvalidProjectConfiguration.new(config_content) unless config.is_a? Hash
      config.each do |key, value|
        break if value.nil?
        value.gsub!(/_pserver:/, ":pserver:")
        value.gsub!(/_local:/, ":local:")
        value.gsub!(/_ext:/, ":ext:")
      end
      config
    end
    
    def project_config(project_name)
      File.open(project_directories.project_config_file(project_name)) do |io|
        parse_project_config(io.gets(nil))
      end
    end
    
    def modify_project_config(project_name, config_map)
      config_map["project_name"] = project_name
      File.open(project_directories.project_config_file(project_name), File::CREAT|File::WRONLY|File::TRUNC) do |io|
        io.puts(config_map.to_yaml)
      end
    end
    
    def create_build(project_name, timestamp)
      Build.new(project_name, timestamp, project_config(project_name))
    end
  end
  
end