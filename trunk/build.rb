#!/usr/local/ruby/bin/ruby
$VERBOSE = nil

#$:<<'lib'

#require 'damagecontrol/FileUtils'
#include DamageControl::FileUtils
#require 'damagecontrol/CruiseControlBridge'
#bridge = DamageControl::CruiseControlBridge.new

#classpath = bridge.classpath
#class_target = "target/classes"
#java_source = "src/main"
#mkdirs("target/classes")
#java_files = []
#java_files<<"CruiseControlBridge.java"
#java_files<<"FakeSourceControl.java"
#sources = java_files.collect{|f| "#{java_source}\\damagecontrol\\#{f}" }.join(" ")
#system("javac -classpath #{classpath} -d #{class_target} -sourcepath #{java_source} #{sources}")
#system("jar cvf lib/damagecontrol.jar -C #{class_target} .")

class Project
	def initialize
		$damagecontrol_home = File::expand_path(".")
		
		$:<<'lib'
		$:<<'lib/rica'
		$:<<'src/ruby'
	end

	def unit_test
		Dir.chdir("#{$damagecontrol_home}/src/ruby")
		system('ruby AllTests.rb')
	end

	def integration_test
		Dir.chdir("#{$damagecontrol_home}/src/ruby")
		system('ruby End2EndTest.rb')
	end
	
	def all
		unit_test
		integration_test
	end
	
	def default
		all
	end
	
	def run(args)
		if args.nil?
			default
		else
			args.each {|target| project.instance_eval(target) }
		end
	end
end

project = Project.new
project.run($ARGV)
