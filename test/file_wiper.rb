require 'test/unit'
require 'fileutils'

module Test #:nodoc:
  module Unit #:nodoc:
    class TestCase #:nodoc:
      def setup_with_file_wiper
        FileUtils.rm_rf "#{DC_DATA_DIR}/projects"
        FileUtils.rm_rf "#{DC_DATA_DIR}/index"
      end
      alias_method :setup, :setup_with_file_wiper 
         
      def self.method_added(method)
        case method.to_s
        when 'setup_with_fixtures'
          unless method_defined?(:setup_without_file_wiper)
            alias_method :setup_without_file_wiper, :setup_with_fixtures
            define_method(:setup_with_fixtures) do
              setup_with_file_wiper
              setup_without_file_wiper
            end
          end
        end
      end
    end
  end
end