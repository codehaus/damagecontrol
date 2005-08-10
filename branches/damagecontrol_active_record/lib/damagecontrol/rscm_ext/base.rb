module RSCM

  class Base
    include ::DamageControl::Dom

    # Available change detection types
    POLLING = "POLLING" unless defined? POLLING
    TRIGGER = "TRIGGER" unless defined? TRIGGER

    attr_accessor :enabled
    attr_accessor :change_detection

    def <=> (o)
      self.class.name <=> o.class.name
    end

    def icon_base
      "/images/#{category}/#{self.class.name.demodulize.underscore}"
    end

    def category
      "scm"
    end

    def exclusive?
      true
    end

    def default_render_excludes
      [:enabled, :fileutils_label, :fileutils_output]
    end

    def has_link?
      false
    end
  end
end
