require 'test/unit'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/SocketTrigger'
require 'ftools'

module DamageControl

	class HTMLPublisher
		
		def process_message(event)
			if event.is_a? BuildCompleteEvent
				path = "dc/#{event.build.project_name}/website"
				filename = "buildresult.html"
				File.makedirs(path)
				create_file(path + "/" +filename)
				
			end
		end
		
		def create_file(file_name)
			file = File.new(file_name, "w")
			file.close
		end
	end

	class HTMLPublisherTest < Test::Unit::TestCase
	
		Testfile = "dc/kingsley/website/buildresult.html"
				
		def teardown
			puts "deleting #{@testfile}"
			File.delete(Testfile) if File.exists?(Testfile)
		end

		def test_buildresults_is_written_in_correct_location_upon_build_complete_event
			hp = HTMLPublisher.new

			def fake_write_file(file_name)
				@fake_file = file_name
				puts "YO #{@fake_file}"
			end

			def hp.create_file(file_name)
				fake_write_file(file_name)
			end

			
			build = Build.new("kingsley")
			hp.process_message(BuildCompleteEvent.new(build))

			puts "BRO #{@fake_file}"

			assert_equal(Testfile, @fake_file)
		end
		
		def test_html_is_not_written_unless_complete_event
			hp = HTMLPublisher.new
			
			def hp.create_file(file_name)
				puts "BRO"
			end
			
			hp.process_message(SocketRequestEvent.new(nil))
			assert(!File.exists?(Testfile), "the file should not exist now")
			
		end
	end
end