require 'test/unit'
require 'pebbles/mockit'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/Hub'
require 'damagecontrol/publisher/FilePublisher'
require 'ftools'

module DamageControl

  class FilePublisherTest < Test::Unit::TestCase
  
    def setup
      @filesystem = MockIt::Mock.new
      @template = MockIt::Mock.new
      @file_publisher = FilePublisher.new(Hub.new, "/path/to/reports", @template)
      @file_publisher.filesystem = @filesystem
    end
  
    def test_file_is_written_in_correct_location_upon_build_complete_event    
      build = Build.new("project_name")
      build.timestamp = "19770614002000"
      
      @template.__setup(:file_type) { "html" }
      @template.__expect(:generate) { |build2|
        "some content"
      }

      @filesystem.__expect(:makedirs) { |dir|
        assert_equal("/path/to/reports/project_name", dir)
      }
      @filesystem.__expect(:newFile) { |file_name, modifiers|
        assert_equal("/path/to/reports/project_name/#{build.timestamp}.html", file_name)
        file = MockIt::Mock.new
        file.__expect(:print) { |content|
          assert_equal("some content", content)
        }
        file.__expect(:flush) {}
        file.__expect(:close) {}
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
