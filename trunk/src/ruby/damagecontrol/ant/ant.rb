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
  # ant_args    arguments to ant (ant targets)
  # vm_args     arguments to pass to the vm
  # ant_home    ant installation directory
  # java_home   jdk installation directory
  # javacmd     java vm executable. if nil, it will be "java"
  # classpath   classpath for ant. if nil it will be calculated.
  # jikespath   path to jikes executable
  #
  def ant_commandline(
    ant_args  = "", \
    vm_args   = ENV['ANT_OPTS'] , \
    ant_home  = ENV['ANT_HOME'] , \
    java_home = ENV['JAVA_HOME'], \
    javacmd   = ENV['JAVACMD']  , \
    classpath = ENV['CLASSPATH'], \
    jikespath = ENV['JIKESPATH'])

    current_dir = Dir.getwd

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
      vm_args << " -Djikes.class.path=#{jikespath}"
    end

    Dir.chdir(current_dir)
    "#{javacmd} -classpath #{classpath} -Dant.home=#{ant_home} #{vm_args} org.apache.tools.ant.Main #{ant_args}"
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
  ant_args = ARGV ? ARGV.join : ""
  cmdline = ant_commandline(ant_args)
  system(cmdline)
end