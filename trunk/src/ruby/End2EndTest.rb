require 'test/unit'
require 'ftools'
require 'damagecontrol/Build'
require 'damagecontrol/SocketTrigger'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/Hub'
require 'damagecontrol/FileUtils'
require 'damagecontrol/BuildBootstrapper'
require 'damagecontrol/scm/SCM'

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

	def create_cvs_repository()
		system("cvs -d#{@cvsroot} init")
	end
		
	class SysOutProgressReporter
		def initialize(hub)
			hub.add_subscriber(self)
		end
		
		def receive_message(message)
			if !message.is_a?(BuildEvent)
				return
			end
			
			name = message.build.project_name
			if message.is_a?(BuildRequestEvent)
				puts "[#{name}] BUILD STARTING"
			end
			
			if message.is_a?(BuildProgressEvent)
				puts "[#{name}] [#{message.build.project_name}] #{message.output}"
			end

			if message.is_a?(BuildCompleteEvent)
				puts "BUILD COMPLETE [#{message.build.project_name}]"
			end
		end
	end
	
	def buildsdir
		"#{@tempdir}/builds"
	end
	
	def start_damagecontrol()
		hub = Hub.new
		SocketTrigger.new(hub).start
		BuildBootstrapper.new(hub, buildsdir).start
		BuildExecutor.new(hub)
	end
	
	def create_cvsmodule(project)
		Dir.chdir(@tempdir)
		File.mkpath(@project)
		Dir.chdir(@project)
		system("cvs -d#{@cvsroot} import -m 'message' #{project} VENDOR START")
	end
	
	def install_damagecontrol_into_cvs
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

	def activate_damagecontrol_in_cvs
		Dir.chdir(@tempdir)
		Dir.chdir("CVSROOT")
		File.open("loginfo", File::WRONLY | File::APPEND) do |file|
			file.puts
			file.puts("DEFAULT #{@cvsrootdir}/CVSROOT/#{script_file("damagecontrol")} #{@project} #{@cvsroot}:#{@project} #{script_file("build")} %{sVv}")
		end
		system("cvs com -m 'message'")
	end
	
	def trigger_script
		script_file("#{@basedir}/src/script/damagecontrol")
	end

	def checkout_cvs_project(project)
		Dir.chdir(@tempdir)
		rmdir(project)
		system("cvs -d#{@cvsroot} co #{project}")
	end
	
	def add_file_to_cvs_project(project, file)
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
	
	def assert_file_content(expected_content, file, message)
		assert(FileTest::exists?(file), "#{file} doesn't exist, #{message}")
		File.open(file) do |io|
			assert_equal(expected_content, io.gets.chomp,
				"#{file} content wrong, #{message}")
		end
	end
	
	def delete_checked_out_project(project)
		Dir.chdir(@tempdir)
		rmdir(project)
	end

        def wait_for_build_to_complete
            sleep 3
        end

        def verify_output_of_build
		assert_file_content('"Hello world from DamageControl" ', 
			"#{buildsdir}/e2eproject/buildresult.txt", 
			"build not executed")
        end

	def test_builds_on_cvs_add
		
		create_cvs_repository
		start_damagecontrol
		create_cvsmodule("e2eproject")
		install_damagecontrol_into_cvs
		activate_damagecontrol_in_cvs
                
		# add build.bat file and commit it (will trigger build)
		checkout_cvs_project("e2eproject")
		File.open("e2eproject/build.bat", "w") do |file|
			file.puts('echo "Hello world from DamageControl" > buildresult.txt')
		end
		add_file_to_cvs_project("e2eproject", "build.bat")
		
		delete_checked_out_project("e2eproject") # will be checked out by bootstrapper
		
		wait_for_build_to_complete
		
                verify_output_of_build
                
	end
        
        def test_builds_on_svn_add
            fail("Mike Mason has promised to do this!")
        end
end