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

  end
end
