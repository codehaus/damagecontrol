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
      super && selected_build.archive_dir && File.exists?(selected_build.archive_dir) && !build_artifacts.empty?
    end
    
    def icon
      "smallicons/component.png"
    end
    
    def build_artifacts
      Dir["#{selected_build.archive_dir}/*"].collect{|f| f[selected_build.archive_dir.length+1..-1]}
    end
    
    def build_artifact_url(file)
      "root/#{selected_build.project_name}/archive/#{selected_build.dc_start_time.ymdHMS}/#{file}"
    end
    
    def content
      erb("components/build_artifacts.erb", binding)
    end
  end
end