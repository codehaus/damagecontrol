require 'damagecontrol/web/Report'

module DamageControl
  class BuildArtifactsReport < Report
    def id
      "artifacts"
    end
    
    def title
      "Build artifacts"
    end
    
    def available?
      super && archive_dir && File.exists?(archive_dir) && !build_artifacts.empty?
    end
    
    def icon
      "smallicons/component.png"
    end
    
    def build_artifacts
      Dir["#{archive_dir}/*"].collect{|f| f[archive_dir.length+1..-1]}
    end
    
    def build_artifact_url(file)
      "root/#{selected_build.project_name}/archive/#{selected_build.dc_creation_time.ymdHMS}/#{file}"
    end
    
    def content
      erb("components/build_artifacts.erb", binding)
    end

  private

    def archive_dir
      @project_directories.archive_dir(selected_build.project_name, selected_build.dc_creation_time)
    end
  end
end