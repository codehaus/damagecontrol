require 'test/unit'
require 'pebbles/mockit'
require 'damagecontrol/util/FilePoller'
require 'damagecontrol/util/FileUtils'

module DamageControl
  
  class FilePollerTest < Test::Unit::TestCase

    include FileUtils

    def setup
      @dir = new_temp_dir
      File.makedirs(@dir)
      
      @file_handler = MockIt::Mock.new
      @poller = FilePoller.new(@dir, @file_handler)
    end

    def teardown
      rm_rf(@dir)
    end
    
    def test_doesnt_trig_on_empty_directory
      @poller.tick
      @file_handler.__verify
    end
    
    def test_new_file_calls_new_file
      @file_handler.__expect(:new_file) { |file_name|
        assert_equal("#{@dir}/newfile", file_name)
      }
    
      create_file("newfile")
      @poller.tick
      @file_handler.__verify
    end
    
    def test_two_new_files_calls_new_file_for_each
      @file_handler.__expect(:new_file) { |file_name|
        assert_equal("#{@dir}/newfile1", file_name)
      }
      @file_handler.__expect(:new_file) { |file_name|
        assert_equal("#{@dir}/newfile2", file_name)
      }

      create_file("newfile1")
      create_file("newfile2")
      @poller.tick
      @file_handler.__verify
    end

  private

    def create_file(filename)
      File.open("#{@dir}/#{filename}", "w") do |file|
        file.puts "bajs"
      end
    end
    
  end
end