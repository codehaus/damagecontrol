class CVSPoller
	attr_accessor :cvsroot
	attr_accessor :cvsmodule
	attr_accessor :last_buildtime
	attr_accessor :executable
	
	def initialize
		executable = "cvs"
	end

	def cvstime (time)
		time.strftime("%Y%m%d %H:%M:%S")
	end
	
	def wasmodified (checktime)
		result  = ""
		command = "#{@executable} -q -d #{@cvsroot} rdiff -D \"#{cvstime(last_buildtime)}\" -D \"#{cvstime(checktime)}\" #{cvsmodule}"
		IO.popen(command) { |p|
			p.each_line { |line|
				result += line
			}
		}
		result.chomp!
		result != ""
	end

end
