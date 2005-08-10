module DamageControl
  # Base class for plugins. Each plugin category should subclass this class, and each
  # plugin in that category should extend that class.
  class Plugin
    cattr_accessor :logger

    def self.become_parent
      unless defined? @@classes
        class_eval <<-EOS
          @@classes = []
          def self.register(cls)
            @@classes << cls unless @@classes.index(cls)
          end

          def self.classes
            @@classes.sort
          end
        EOS
      end
    end
    
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