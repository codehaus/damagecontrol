
module DamageControl

  class ShortTextTemplate  
    def generate(build)
      # TODO make this work for real (with CruiseControl bridge for example)
      # htmlurl = "#{webpath(build)}/#{build.reports_path}/#{build.label}.html}"
      "BUILD #{build.status} #{build.project_name} #{build.label}"
    end

    def file_type
      "txt"
    end

    #def webpath(build)
    #  @webpath ? @webpath : "http://#{build.scm.host(build.scm_spec)"
    #end
  end
end