
module DamageControl

  class ShortTextTemplate  
    def generate(build)
      "[#{build.project_name}] BUILD #{build.status} #{build.label}"
    end

    def file_type
      "txt"
    end
  end
end