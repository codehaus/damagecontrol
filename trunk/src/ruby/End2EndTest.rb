require 'test/unit'
require 'damagecontrol/Project'
require 'damagecontrol/SocketTrigger'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/Hub'
require 'damagecontrol/FileUtils'

include DamageControl

class End2EndTest < Test::Unit::TestCase
	
	include FileUtils

	def copy(from, to)
		from = File.expand_path(from)
		to = File.expand_path(to)
		File.open(from) do |from_file|
			File.open(to, File::CREAT | File::WRONLY) do |to_file|
				to_file.puts(from_file.gets(nil))
			end
		end
	end
	
	def setup
		@basedir = "../.."
		Dir.mkdir("#{@basedir}/target")
		@tempdir = File.expand_path("#{@basedir}/target/temp_e2e_#{Time.new.to_i}")
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
	
	def start_damagecontrol(build_command_line)
		project = Project.new(@project)
		def project.build
			puts "building #{self}"
			super()
			puts "built #{self}"
		end
		project.basedir = "#{@tempdir}/#{@project}"
		project.build_command_line = build_command_line
		hub = Hub.new
		SocketTrigger.new(hub, project).start
		BuildExecutor.new(hub)
	end
	
	def create_cvsmodule(project)
		Dir.chdir(@tempdir)
		mkdirs(@project)
		Dir.chdir(@project)
		system("cvs -d#{@cvsroot} import -m 'message' #{project} VENDOR START")
	end
	
	def install_damagecontrol()
		Dir.chdir(@tempdir)
		system("cvs -d#{@cvsroot} co CVSROOT")
		copy("#{@basedir}/src/cvsx/damagecontrol.bat", "CVSROOT/damagecontrol.bat")
		system("cvs -d#{@cvsroot} add damagecontrol.bat")
		File.open("CVSROOT/loginfo", File::WRONLY | File::TRUNC) do |file|
			file.puts("DEFAULT #{trigger_script} #{@project} %{sVv}")
		end
		system("cvs com -m 'message' CVSROOT")
	end
	
	def trigger_script
		script_file("${basedir}/src/script/damagecontrol")
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
		checkout("e2eproject")

		# add build.bat file and commit it (will trigger build)
		File.open("e2eproject/build.bat", "w") do |file|
			file.puts('echo "Hello world from DamageControl"')
			file.puts('echo "Hello world from DamageControl" > buildresult.txt')
		end
		# will trigger a build
		add_file("e2eproject", "build.bat")
		
		# wait for build to complete
		sleep 1
		
		# verify output of build
		buildresult = "#{@tempdir}/e2eproject/buildresult.txt"
		assert(FileTest::exists?(buildresult))
		File.open(buildresult) do |file|
			assert_equal('"Hello world from DamageControl" ', file.gets.chomp)
		end
		
	end
end