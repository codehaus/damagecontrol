require 'test/unit'
require 'damagecontrol/Build'
require 'damagecontrol/SocketTrigger'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/Hub'
require 'damagecontrol/FileUtils'

include DamageControl

class End2EndTest < Test::Unit::TestCase
	
	include FileUtils

	def setup
		@basedir = File.expand_path("../..")
		@tempdir = "#{@basedir}/target/temp_e2e_#{Time.new.to_i}"
		mkdirs(@tempdir)
		Dir.chdir(@tempdir)
		@cvsrootdir = "#{@tempdir}/repository"
		@cvsroot = ":local:#{@cvsrootdir}"
		@project = "e2eproject"
	end
	
	def teardown
		Dir.chdir(@tempdir)
		begin
			delete(@project)
			delete(@cvsrootdir)
		rescue
		end
	end

	def create_repository()
		system("cvs -d#{@cvsroot} init")
	end
	
	class BuildBootstrapper
		def initialize(hub, basedir, build_command_line)
			@hub = hub
			@hub.add_subscriber(self)
			@basedir = basedir
			@build_command_line = build_command_line
		end
		
		def bootstrap_build(build_spec)
			build = Build.new(@project)
			def build.build
				puts "building #{self}"
				super()
				puts "built #{self}"
			end
			build.basedir = @basedir
			build.build_command_line = @build_command_line
			build
		end
		
		def receive_message(message)
			if (message.is_a?(SocketRequestEvent))
				build = bootstrap_build(message.payload)
				@hub.publish_message(BuildRequestEvent.new(build))
			end
		end
	end
	
	def start_damagecontrol(build_command_line)
		hub = Hub.new
		SocketTrigger.new(hub).start
		BuildBootstrapper.new(hub, "#{@tempdir}/#{@project}", script_file("build"))
		BuildExecutor.new(hub)
	end
	
	def create_cvsmodule(project)
		Dir.chdir(@tempdir)
		mkdirs(@project)
		Dir.chdir(@project)
		system("cvs -d#{@cvsroot} import -m 'message' #{project} VENDOR START")
	end
	
	def install_damagecontrol
		Dir.chdir(@tempdir)
		system("cvs -d#{@cvsroot} co CVSROOT")
		Dir.chdir("CVSROOT")
		copy("#{trigger_script}", script_file("damagecontrol"))
		system("cvs -d#{@cvsroot} add damagecontrol.bat")
		File.open("checkoutlist", File::WRONLY | File::APPEND) do |file|
			file.puts
			file.puts(script_file('damagecontrol'))
		end
		system("cvs com -m 'message'")
	end

	def activate_damagecontrol
		Dir.chdir(@tempdir)
		Dir.chdir("CVSROOT")
		File.open("loginfo", File::WRONLY | File::APPEND) do |file|
			file.puts
			file.puts("DEFAULT #{trigger_script} #{@project} %{sVv}")
		end
		system("cvs com -m 'message'")
	end
	
	def trigger_script
		script_file("#{@basedir}/src/script/damagecontrol")
	end

	def checkout(project)
		Dir.chdir(@tempdir)
		delete(project)
		system("cvs -d#{@cvsroot} co #{project}")
	end
	
	def add_file(project, file)
		Dir.chdir("#{@tempdir}/#{project}")
		system("cvs add #{file}")
		system("cvs com -m 'comment'")
	end
	
	def script_file(file)
		"#{file}.bat"
	end

	def test_builds_on_cvs_add
		
		create_repository()
		start_damagecontrol(script_file("build"))
		create_cvsmodule("e2eproject")
		install_damagecontrol()
		activate_damagecontrol()

		# add build.bat file and commit it (will trigger build)
		checkout("e2eproject")
		File.open("e2eproject/build.bat", "w") do |file|
			file.puts('echo "Hello world from DamageControl"')
			file.puts('echo "Hello world from DamageControl" > buildresult.txt')
		end
		add_file("e2eproject", "build.bat")
		
		# wait for build to complete
		sleep 1
		
		# verify output of build
		buildresult = "#{@tempdir}/e2eproject/buildresult.txt"
		assert(FileTest::exists?(buildresult), "build not executed, build result not created")
		File.open(buildresult) do |file|
			assert_equal('"Hello world from DamageControl" ', file.gets.chomp)
		end
		
	end
end