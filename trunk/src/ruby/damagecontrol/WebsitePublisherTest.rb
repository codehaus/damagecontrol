require 'test/unit'
require 'damagecontrol/WebsitePublisher'
require 'damagecontrol/FileUtils'

module DamageControl

	class WebsitePublisherTest < Test::Unit::TestCase
	
		include FileUtils
		
		def setup
			@hub = Hub.new
			@publisher = WebsitePublisher.new(@hub)
			@project = Project.new("Bob")
			@project.logs_directory = "logs"
			@project.website_directory = "out"
			@result = ""
			Dir.mkdir("logs") if !File.exists?("logs")
			foreach_log {|log|
				File.open("logs/#{log}.log", "w") {|file| file.puts("Build results #{log}")}
			}
		end
		
		def foreach_log
			3.times {|i|
				log = "#{i}"
				yield(log)
			}
		end
		
		def test_creates_dir_and_index_file
			@hub.publish_message( BuildCompleteEvent.new( @project ) )
			assert(FileTest.exists?("out"), "directory should exist")
			assert(FileTest.exists?("out/index.html"), "index file should exist")
		end
		
		def test_writes_project_summary_and_lists_logs
			@publisher.receive_message( BuildCompleteEvent.new( @project ) )
			index_content = content(@project.website_file("index.html"))
			assert_contain( @project.name, index_content )
			foreach_log {|log|
				assert_contain( "#{log}", index_content )
				assert_contain( "#{log}.html", index_content )
			}
			assert_not_contain( "..", index_content )
		end
		
		def test_writes_content_of_logs
			@publisher.receive_message( BuildCompleteEvent.new( @project ) )
			foreach_log {|log|
				assert( FileTest::exists?( @project.website_file("#{log}.html") ) )
				published_content = content(@project.website_file(log + ".html"))
				log_content = content("logs/#{log}.log")
				assert_contain( log_content, published_content )
			}
		end

		def assert_contain(expected, actual)
			assert( actual.index(expected) , "<#{actual}> should contain <#{expected}>")
		end
		
		def assert_not_contain(expected, actual)
			assert( !actual.index(expected), "<#{actual}> should not contain <#{expected}>")
		end
		
		def content(file)
			text = ""
			File.open(file) { |file|
				file.each_line {|line| text += line }
			}
			return text
		end
		
		def teardown
			delete("logs")
			delete("out")
		end
				
	end
	
end