require 'test/unit'

module DamageControl

	class WebsitePublisherTest < Test::Unit::TestCase
		def setup
			@publisher = WebsitePublisher.new()
			@project = Project.new("Bob")
			@project.logs_directory = "logs"
			@project.website_directory = "out"
			@result = ""
			Dir.mkdir("logs") if !File.exists?("logs")
			3.times {|i|
				File.open("logs/#{i}.log", "w") {|file| file.puts("Build results #{i}")}
			}
		end
		
		def test_dont_show
			assert(@publisher.dont_show("."), "shows .")
			assert(!@publisher.dont_show("1.log"), "doesn't show 1.log")
		end

		def test_creates_dir_and_index_file
			@publisher.receive_message( BuildCompleteEvent.new( @project, @result ) )
			assert(FileTest.exists?("out"), "directory should exist")
			assert(FileTest.exists?("out/index.html"), "index file should exist")
		end
		
		def test_writes_project_summary_and_lists_files
			@publisher.receive_message( BuildCompleteEvent.new( @project, @result ) )
			index_content = content("out/index.html")
			assert_contain( @project.name, index_content )
			assert_contain( @project.name, index_content )
			3.times {|i|
				assert_contain( "#{i}", index_content )
			}
			assert_not_contain( ".", index_content )
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
		
		def xteardown
			File.delete("out/index.html")
			Dir.delete("out")
			Dir.foreach("logs") {|filename| "logs/" + File.delete(filename) }
			Dir.delete("logs")
		end
	end
	
	class WebsitePublisher
		def receive_message( event )
			@project = event.project
			Dir.mkdir(@project.website_directory) if !File.exists?(@project.website_directory)
			File.open( @project.website_directory + File::SEPARATOR + "index.html", "w") { |file|
				file.print(main_page_template())
			}
		end
			
		def main_page_template
 			"<html><body>Project name: #{@project.name} <br> <br> #{build_list}</body></html>"
		end
		
		def build_list
		 	result = "<ul>"
			Dir.foreach(@project.logs_directory) {|filename| 
				if !dont_show(filename)
					filename = filename[0, filename.rindex('.')]
					result += "<li>#{filename}"
				end
			}
		 	result += "</ul>"
		 	return result
		end
		
		def dont_show(filename)
			/^\..*/ =~ filename
		end
	end

end