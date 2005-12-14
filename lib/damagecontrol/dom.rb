module DamageControl
  # This module adds HTML DOM methods to objects
  module Dom
    def enabled_icon
      "#{icon_base}.png"
    end

    def disabled_icon
      "#{icon_base}_grey.png"
    end

    # Returns +enabled_icon+ if the instance is +enabled+, or
    # +disabled_icon+ if not.
    def icon
      enabled ? enabled_icon : disabled_icon
    end

    # A unique HTML DOM id that is W3C compliant
    def dom_id
      "#{category}_#{self.class.name.demodulize.underscore}"
    end

    def enabled_id
      "#{dom_id}_enabled"
    end

    def visual_name
      self.class.name.demodulize
    end

    def underscored_name
      self.class.name.demodulize.underscore
    end

    def icon_base
      "/images/plugin/#{category}/#{underscored_name}"
    end

    def default_render_excludes
      [:enabled, :fileutils_label, :fileutils_output, :content_type, :uses_polling, :enabling_states]
    end

    def <=> (other)
      self.class.name <=> other.class.name
    end

  end
end
