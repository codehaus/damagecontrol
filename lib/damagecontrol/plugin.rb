module DamageControl

  module Plugin
    
    include Dom

    def name
      self.class.name.demodulize
    end

    def icon_base
      "/images/#{category}/#{name.underscore}"
    end

    def default_render_excludes
      [:enabled, :fileutils_label, :fileutils_output]
    end

    def has_link?
      false
    end

    def <=> (other)
      self.class.name <=> other.class.name
    end

  end
end