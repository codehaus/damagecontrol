require 'test/unit'
require 'mock_with_returns'
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
      @filesystem = Mock.new
      @template = Mock.new
      @file_publisher = FilePublisher.new(Hub.new, "/some/where", @template, @filesystem)
    end
  
    def test_file_is_written_in_correct_location_upon_build_complete_event    
      build_result = BuildResult.new
      build_result.label = "123"
      
      @template.__return(:file_name, "trash.txt")
      @template.__next(:generate) { |build_result2|
        "some content"
      }

      @filesystem.__next(:makedirs) { |dir|
        assert_equal("/some/where/123", dir)
      }
      @filesystem.__next(:newFile) { |file_name, modifiers|
        assert_equal("/some/where/123/trash.txt", file_name)
        file = Mock.new
        file.__next(:print) { |content|
          assert_equal("some content", content)
        }
        file.__next(:close) {}
        return file
      }
      
      @file_publisher.process_message(BuildCompleteEvent.new(build_result))

      @template.__verify
      @filesystem.__verify
    end
    
    def test_nothing_is_written_unless_build_complete_event
      @file_publisher.process_message(SocketRequestEvent.new(nil))
      @template.__verify
      @filesystem.__verify
    end
    
  end
end