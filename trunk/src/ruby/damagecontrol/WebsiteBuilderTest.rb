require 'test/unit'

module DamageControl
	module WebsiteBuilder

		class WebsiteBuilderTest < Test::Unit::TestCase
			def setup
				@builder = WebsiteBuilder.new()
				@project = Project.new("Bob")
				@project.logs_directory = "logs"
				@project.website_directory = "out"
				Dir.mkdir("logs") if !File.exists?("logs")
				(1..3).each {|i|
					File.open("logs/#{i}.log", "w") {|file| file.puts("Build results #{i}")}
				}
			end
			
			def test_dont_show
				assert(@builder.dont_show("."), "shows .")
				assert(!@builder.dont_show("1.log"), "doesn't show 1.log")
			end

			def test_creates_dir_and_index_file
				@builder.receive_message( BuildCompleteEvent.new(@project) )
				assert(FileTest.exists?("out"), "directory should exist")
				assert(FileTest.exists?("out/index.html"), "index file should exist")
			end
			
			def test_writes_project_summary_and_lists_files
				@builder.receive_message( BuildCompleteEvent.new(@project) )
				index_content = content("out/index.html")
				assert_contain( @project.name, index_content )
				assert_contain( @project.name, index_content )
				(1..3).each {|i|
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
		
		class WebsiteBuilder
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
		
		class Project
			attr_reader :name
			attr_accessor :website_directory, :logs_directory
			def initialize (name)
				@name = name
			end
		end
		
		class BuildCompleteEvent
			attr_reader :project
			def initialize( project )
				@project = project
			end
		end
		
		
	
	end
end