module DamageControl

  class ShortTextTemplate
    def generate(build)
      success_message = build.successful ? "successful" : "failed"
      "Build of #{build.project_name} #{success_message} (http://www.codehaus.org/)"
    end
  end
end