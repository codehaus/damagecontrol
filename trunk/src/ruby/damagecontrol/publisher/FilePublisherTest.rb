require 'test/unit'
require 'mock_with_returns'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/Build'
require 'damagecontrol/Hub'
require 'damagecontrol/publisher/FilePublisher'
require 'damagecontrol/template/MockTemplate'
require 'ftools'

module DamageControl

  class FilePublisherTest < Test::Unit::TestCase
  
    def setup
      @filesystem = Mock.new
      @template = Mock.new
      @file_publisher = FilePublisher.new(Hub.new, "/path/to/reports", @template)
      @file_publisher.filesystem = @filesystem
    end
  
    def test_file_is_written_in_correct_location_upon_build_complete_event    
      build = Build.new("project_name")
      build.timestamp = "19770614002000"
      
      @template.__return(:file_type, "html")
      @template.__next(:generate) { |build2|
        "some content"
      }

      @filesystem.__next(:makedirs) { |dir|
        assert_equal("/path/to/reports/project_name", dir)
      }
      @filesystem.__next(:newFile) { |file_name, modifiers|
        assert_equal("/path/to/reports/project_name/#{build.timestamp}.html", file_name)
        file = Mock.new
        file.__next(:print) { |content|
          assert_equal("some content", content)
        }
        file.__next(:flush) {}
        file.__next(:close) {}
        return file
      }
      
      @file_publisher.process_message(BuildCompleteEvent.new(build))

      @template.__verify
      @filesystem.__verify
    end
    
    def test_nothing_is_written_unless_build_complete_event
      @file_publisher.process_message("event")
      @template.__verify
      @filesystem.__verify
    end
    
  end
end
