require 'test/unit'
require 'damagecontrol/HTMLPublisher'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/SocketTrigger'
require 'ftools'

module DamageControl

	class HTMLPublisherTest < Test::Unit::TestCase
	
		Testfile = "dc/kingsley/website/buildresult.html"
				
		def teardown
			puts "deleting #{@testfile}"
			File.delete(Testfile) if File.exists?(Testfile)
		end

		def test_buildresults_is_written_in_correct_location_upon_build_complete_event
			hp = HTMLPublisher.new

			# mock out i/o
			def hp.create_file(file_name)
				@file_name = file_name
			end
			
			def hp.verify(test)
				test.assert_equal(Testfile, @file_name)
			end
			
			build = Build.new("kingsley")
			hp.process_message(BuildCompleteEvent.new(build))
			hp.verify(self)
		end
		
		def test_html_is_not_written_unless_complete_event
			hp = HTMLPublisher.new
			
			# mock out i/o
			def hp.create_file(file_name)
				@file_name = file_name
			end
			
			def hp.verify(test)
				test.assert_nil(@file_name)
			end
			
			hp.process_message(SocketRequestEvent.new(nil))
			hp.verify(self)
		end
	end
end