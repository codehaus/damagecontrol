require 'damagecontrol/Project'
require 'damagecontrol/SocketTrigger'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/Hub'

include DamageControl

Dir.chdir("../../target")

cvsroot=":local:C:/Projects/damagecontrol/target/repository"

# create repository
system("cvs -d#{cvsroot} init")

# start damagecontrol with SocketTrigger (and so on)
project = Project.new("e2eproject")
def project.build
	puts "build called on project"
	super()
end
project.basedir = "C:/Projects/damagecontrol/target/e2eproject"
project.build_command_line = "build.bat"
hub = Hub.new
SocketTrigger.new(hub, project).start
BuildExecutor.new(hub)

def mkdir(dir)
	Dir.mkdir(dir) unless FileTest::exists?(dir)
end
def copy(from, to)
	from = File.expand_path(from)
	to = File.expand_path(to)
	File.open(from) do |from_file|
		File.open(to, File::CREAT | File::WRONLY) do |to_file|
			to_file.puts(from_file.gets(nil))
		end
	end
end

# import project into CVS module
mkdir("e2eproject")
Dir.chdir("e2eproject")
system("cvs -d#{cvsroot} import -m 'message' e2eproject VENDOR START")

# install damagecontrol callback into loginfo
Dir.chdir("..")
system("cvs -d#{cvsroot} co CVSROOT")
copy("../src/cvsx/damagecontrol.bat", "CVSROOT/damagecontrol.bat")
system("cvs -d#{cvsroot} add damagecontrol.bat")
File.open("CVSROOT/loginfo", File::WRONLY | File::TRUNC) do |file|
	file.puts("DEFAULT c:/Projects/damagecontrol/src/cvsx/damagecontrol.bat e2eproject %{sVv}")
end
system("cvs com -m 'message' CVSROOT")

# check out project again
Dir.rmdir("e2eproject")
system("cvs -d#{cvsroot} co e2eproject")
Dir.chdir("e2eproject")
# add build.bat file and commit it (will trigger build)
File.open("build.bat", "w") do |file|
	file.puts('echo "Hello world from DamageControl"')
	file.puts('echo "Hello world from DamageControl" > buildresult.txt')
end
system("cvs add build.bat")
system("cvs com -m 'comment'")

# wait for some time (5s)
sleep 1

# verify output of build
Dir.chdir("..")
File.open("e2eproject/buildresult.txt") do |file|
	puts file.gets
end
