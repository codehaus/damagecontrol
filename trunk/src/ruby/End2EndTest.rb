require 'test/unit'
require 'ftools'
require 'damagecontrol/Build'
require 'damagecontrol/SocketTrigger'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/Hub'
require 'damagecontrol/FileUtils'
require 'damagecontrol/BuildBootstrapper'
require 'ftools'

include DamageControl

class End2EndTest < Test::Unit::TestCase
	
	include FileUtils

	def setup
		@basedir = damagecontrol_home
		@tempdir = "#{@basedir}/target/temp_e2e_#{Time.new.to_i}"
		File.mkpath(@tempdir)
		Dir.chdir(@tempdir)
		@cvsrootdir = "#{@tempdir}/repository"
		@cvsroot = ":local:#{@cvsrootdir}"
		@project = "e2eproject"
	end
	
	def teardown
		Dir.chdir(@tempdir)
		rmdir(@project)
		rmdir(@cvsrootdir)
	end

	def create_repository()
		system("cvs -d#{@cvsroot} init")
	end
		
	def start_damagecontrol(build_command_line)
		hub = Hub.new
		SocketTrigger.new(hub).start
		BuildBootstrapper.new(hub, "#{@tempdir}")
		BuildExecutor.new(hub)
	end
	
	def create_cvsmodule(project)
		Dir.chdir(@tempdir)
		File.mkpath(@project)
		Dir.chdir(@project)
		system("cvs -d#{@cvsroot} import -m 'message' #{project} VENDOR START")
	end
	
	def install_damagecontrol
		# install the trigger script
		Dir.chdir(@tempdir)
		system("cvs -d#{@cvsroot} co CVSROOT")
		Dir.chdir("CVSROOT")
		File.copy("#{trigger_script}", script_file("damagecontrol"))
		system("cvs -d#{@cvsroot} add damagecontrol.bat")
		
		# install the nc.exe
		File.copy( "#{@basedir}/bin/#{nc_file}", "#{@tempdir}/CVSROOT/#{nc_file}" )
		system("cvs -d#{@cvsroot} add -kb #{nc_file}")
		
		# tell cvs to keep a non-,v file in the central repo
		File.open("checkoutlist", File::WRONLY | File::APPEND) do |file|
			file.puts
			file.puts(script_file('damagecontrol'))
			file.puts(nc_file)
		end
		system("cvs com -m 'message'")
	end

	def activate_damagecontrol
		Dir.chdir(@tempdir)
		Dir.chdir("CVSROOT")
		File.open("loginfo", File::WRONLY | File::APPEND) do |file|
			file.puts
			file.puts("DEFAULT #{@cvsrootdir}/CVSROOT/#{script_file("damagecontrol")} #{@project} #{@cvsroot} #{script_file("build")} %{sVv}")
		end
		system("cvs com -m 'message'")
	end
	
	def trigger_script
		script_file("#{@basedir}/src/script/damagecontrol")
	end

	def checkout(project)
		Dir.chdir(@tempdir)
		rmdir(project)
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

	def nc_file
		"nc.exe"
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