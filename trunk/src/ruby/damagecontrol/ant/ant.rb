module Ant
  # Creates a command line for executing Ant. Can be used
  # as a standalone script or as a class if called from
  # a different ruby script.
  #
  # If called from another ruby script, the command can be
  # executed with system or IO.popen
  #
  # Author Aslak Hellesoy
  #
  # @param javacmd java vm executable
  # @classpath classpath for ant. if nil, it will be calculated
  # @ant_home ant installation directory
  # @ant_opts options to pass to the vm
  # @args options to pass to ant
  #
  def commandline(
    args      = "", \
    ant_opts  = ENV['ANT_OPTS'], \
    ant_home  = ENV['ANT_HOME'],\
    jikespath = ENV['JIKESPATH'], \
    java_home = ENV['JAVA_HOME'], \
    javacmd   = ENV['JAVACMD'], \
    classpath = ENV['CLASSPATH'] \
    )

    if( !ant_home )
      raise "ant_home *MUST* be set!"
    end
    
    if( !javacmd )
      javacmd = "java"      
    end
    
    if( !classpath )
      classpath = ""
      libdir = File.join(ant_home, "lib")
      Dir.chdir(libdir)
      jarfiles = Dir["*.{jar,zip}"]
      jarfiles.each { |jarfile|
        classpath << "#{File.join(libdir,jarfile)}#{File::PATH_SEPARATOR}"
      }
    end
    if( java_home )
      tools = File.join(java_home, "lib", "tools.jar")
      classes = File.join(java_home, "lib", "classes.zip")
      classpath << "#{File::PATH_SEPARATOR}#{tools}#{File::PATH_SEPARATOR}#{classes}"
    end
    
    if( jikespath )
      ant_opts << " -Djikes.class.path=#{jikespath}"
    end

    "#{javacmd} -classpath #{classpath} -Dant.home=#{ant_home} #{ant_opts} org.apache.tools.ant.Main #{args}"
  end
end

if( !ENV['ANT_HOME'] )
  raise "ANT_HOME *MUST* be set!"
end

if( !ENV['JAVA_HOME'] )
  puts "\n\nWarning: JAVA_HOME environment variable is not set.\n", \
    "If the build fails because sun.* classes could not be found\n", \
    "you will need to set the JAVA_HOME environment variable\n", \
    "to the installation directory of java\n"
end

if($0 == __FILE__)
  include Ant
  args = ARGV ? ARGV.join : ""
  cmdline = commandline(args)
  system(cmdline)
end