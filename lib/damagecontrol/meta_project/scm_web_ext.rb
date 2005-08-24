module MetaProject
  class ScmWeb
    include ::DamageControl::Dom
    
    def enabled
      true
    end

    def category
      "project"
    end
    
    def exclusive?
      false
    end

  end
end
