require 'damagecontrol/Project'
require 'damagecontrol/BuildCompleteEvent'

module DamageControl

	class WebsitePublisher
		def initialize (hub)
			hub.add_subscriber(self)
		end
	
		def receive_message (message)
			if message.is_a? BuildCompleteEvent
				@project = message.project
				@project.open_website_file("index.html") { |file|
					file.print(main_page())
				}
				@project.foreach_log { |log|
					@project.open_website_file("#{log.name}.html") { |file|
						file.print(log_page(log))
					}
				}
			end
		end
		
		def title
			@project.name
		end
		
		def log_page (log)
			result = ""
			log.open_log_file { |file|
				file.each_line {|line| result += line }
			}
			result
		end
			
		def main_page
		%{
<html>
<head>
	<title>#{title}</title>
	<link rel="stylesheet" href="#{style_link}" type="text/css" />
</head>
<body>
		<div class="main">
	       <h3 class="projectname">#{title}</h3>
#{format_build_logs_list()}
		</div>

#{format_side_menu}
</body>
</html>
}
		end
		
		def style_link
			"about:blank"
		end
		
		def format_side_menu
		end
		
		def format_build_logs_list
			%{	
			<ul class='logs'>
			#{format_build_logs()}
			</ul>
			}
		end
		
		def format_build_logs
			result = "<ul>"
			@project.foreach_log {|log|
				result +=
				%{<li class='log'>
					<a href='#{log.name}.html' class='loglink'>#{log.name}</a>
				</li>}
			}
		 	result += "</ul>"
		 	return result
		end
	end

end