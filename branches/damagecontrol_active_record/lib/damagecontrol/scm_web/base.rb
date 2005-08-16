module DamageControl
  module ScmWeb
    class Base
      include Plugin

      def self.classes
        [
          Chora,
          DamageControl,
          Fisheye,
          Trac,
          ViewCvs
        ]
      end

      attr_accessor :enabled

      def category
        "scm_web"
      end

      def exclusive?
        true
      end
    end
  end
end

Dir[File.dirname(__FILE__) + "/*.rb"].each do |src|
  require src unless src == __FILE__
end
