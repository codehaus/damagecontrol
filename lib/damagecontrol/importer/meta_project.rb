module MetaProject
  module ProjectAnalyzer
    def import_from_meta_project(project, scm_web_url, options)
      meta_project = project_from_scm_web(scm_web_url, options)
      if(meta_project)
        project.name          = meta_project.name
        project.home_page     = meta_project.home_page
        project.tracker       = meta_project.tracker
        project.scm_web       = meta_project.scm_web
        project.scm           = meta_project.scm

        build_tool = meta_project.build_tool
        project.build_command = build_tool.build_command

        artifact_archiver = DamageControl::Publisher::ArtifactArchiver.new
        artifact_archiver.files = build_tool.artifacts
        artifact_archiver.enabling_states = [Build::Successful.new, Build::Fixed.new]
        project.publishers    = [artifact_archiver] # TODO: add mailing lists here

        project.save
      end
    end
  end
end