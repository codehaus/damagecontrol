
module DamageControl

  class ShortTextTemplate  
    def generate(build)
      success_message = build.successful ? "SUCCESSFUL" : "FAILED"
      # TODO make this work for real (with CruiseControl bridge for example)
      # htmlurl = "#{webpath(build)}/#{build.reports_path}/#{build.label}.html}"
      "BUILD #{success_message} #{build.project_name} #{build.label}"
    end

    #def webpath(build)
    #  @webpath ? @webpath : "http://#{build.scm.host(build.scm_spec)"
    #end
  end
end