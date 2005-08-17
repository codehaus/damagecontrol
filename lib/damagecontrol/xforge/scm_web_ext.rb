module ScmWeb
  class Base
    include ::DamageControl::Plugin

    attr_accessor :enabled

    def category
      "scm_web"
    end

    def exclusive?
      true
    end
  end
end
