
def mkdirs(dirs)
	dir = ""
	dirs.split("\\").each{|entry|
		dir += entry
		Dir.mkdir(dir) unless FileTest::exists?(dir)
		dir += "/"
	}
end

$:<<'src/ruby'
$:<<'lib'

require 'damagecontrol/CruiseControlBridge'
bridge = DamageControl::CruiseControlBridge.new
classpath = bridge.classpath
class_target = "target/classes"
java_source = "src/main"
mkdirs("target/classes")
java_files = []
java_files<<"CruiseControlBridge.java"
java_files<<"FakeSourceControl.java"
sources = java_files.collect{|f| "#{java_source}\\damagecontrol\\#{f}" }.join(" ")
system("javac -classpath #{classpath} -d #{class_target} -sourcepath #{java_source} #{sources}")
system("jar cvf lib/damagecontrol.jar -C #{class_target} .")

require 'AllTests'