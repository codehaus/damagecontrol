if( ENV['ANT_HOME'] )
  ANT_HOME = ENV['ANT_HOME']
else
  puts "\n\nANT_HOME *MUST* be set!\n\n"  
  exit(1)
end

if( ENV['JAVACMD'] )
  JAVACMD = ENV['JAVACMD']
else
  JAVACMD = "java"
end

if( ENV['CLASSPATH'] )
  CLASSPATH = ENV['CLASSPATH']
else
  CLASSPATH = ""
  LIBDIR = File.join(ANT_HOME, "lib")
  Dir.chdir(LIBDIR)
  jarfiles = Dir["*.{jar,zip}"]
  jarfiles.each { |jarfile|
    CLASSPATH << "#{File.join(LIBDIR,jarfile)}#{File::PATH_SEPARATOR}"
  }
end

if( ENV['JAVA_HOME'] )
  JAVA_HOME = ENV['JAVA_HOME']
  TOOLS = File.join(JAVA_HOME, "lib", "tools.jar")
  CLASSES = File.join(JAVA_HOME, "lib", "classes.zip")
  CLASSPATH << "#{CLASSPATH}#{TOOLS}"
else
  puts "\n\nWarning: JAVA_HOME environment variable is not set.\n", \
    "If the build fails because sun.* classes could not be found\n", \
    "you will need to set the JAVA_HOME environment variable\n", \
    "to the installation directory of java\n"
end

ANT_OPTS = []
if( ENV['ANT_OPTS'] )
  ANT_OPTS << ENV['ANT_OPTS'].split
end
if( ENV['JIKESPATH'] )
  ANT_OPTS << "-Djikes.class.path= ENV['JIKESPATH']"
end

cmdline = "#{JAVACMD} -classpath #{CLASSPATH} -Dant.home=#{ANT_HOME} #{ANT_OPTS.join} org.apache.tools.ant.Main #{ARGV.join}"

system(cmdline)

