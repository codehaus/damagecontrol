module DamageControl

  module Plugin
    
    def name
      self.class.name.demodulize
    end
    
    def <=> (other)
      self.class.name <=> other.class.name
    end
    
    def htmlize(str)
      str.gsub(/\n/, "<br/>")
    end

    include Dom

    def icon_base
      "/images/#{category}/#{self.class.name.demodulize.underscore}"
    end

    def default_render_excludes
      [:enabled, :fileutils_label, :fileutils_output]
    end

    def has_link?
      false
    end
  end
end