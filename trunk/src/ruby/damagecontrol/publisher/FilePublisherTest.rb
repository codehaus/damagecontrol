require 'test/unit'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/BuildResult'
require 'damagecontrol/Hub'
require 'damagecontrol/publisher/FilePublisher'
require 'damagecontrol/templates/MockTemplate'
require 'damagecontrol/SocketTrigger'
require 'ftools'

module DamageControl

  class FilePublisherTest < Test::Unit::TestCase
  
    def setup
      @mock_template = MockTemplate.new
      @file_publisher = FilePublisher.new(Hub.new, "/some/where", @mock_template)

      # mock out i/o
      def @file_publisher.makedirs(dir)
        @dir = dir
      end

      def @file_publisher.write_to_file(filepath, content)
        @filepath = filepath
      end
    end
  
    def test_file_is_written_in_correct_location_upon_build_complete_event
      @mock_template.expected_to_generate = true
    
      build_result = BuildResult.new
      build_result.label = "123"
      
      def @file_publisher.verify(test)
        test.assert_equal("/some/where/123", @dir)
        test.assert_equal("/some/where/123/trash.txt", @filepath)
      end
      
      @file_publisher.process_message(BuildCompleteEvent.new(build_result))
#      @file_publisher.verify(self)
      @mock_template.verify(self)
    end
    
    def test_nothing_is_written_unless_build_complete_event
      @mock_template.expected_to_generate = false
      
      def @file_publisher.verify(test)
        test.assert_nil(@dir)
        test.assert_nil(@filepath)
      end
      
      @file_publisher.process_message(SocketRequestEvent.new(nil))
      @file_publisher.verify(self)

      @mock_template.verify(self)
    end
    
  end
end