module MetaProject
  module ScmWeb
    # TODO: delete this file?
    class Browser
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
