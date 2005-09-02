module MetaProject
  module ScmWeb
    class Browser
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
end
