require 'rexml/document'
require 'ParseDate'


module DamageControl

  class CruiseControlBridge
    attr_accessor :jars
    attr_accessor :sourcecontrol
    attr_accessor :bridge
    attr_accessor :parameters
    
    def initialize
      @jars = []
      @jars<<"cruisecontrol-2.1.3.jar"
      @jars<<"log4j-1.2.8.jar"
      @jars<<"jdom-b8.jar"
      @jars<<"commons-beanutils-1.6.1.jar"
      @jars<<"commons-logging-1.0.1.jar"
      @jars<<"commons-collections-2.1.jar"
      @jars<<"damagecontrol.jar"
      @libdir = "../../lib"
      @bridge = "damagecontrol.CruiseControlBridge"
      @parameters = {}
    end
    
    def classpath
      jars.collect{|jar| find_jar(jar) }.join(File::PATH_SEPARATOR)
    end
    
    def find_jar jar
      $:.each{|libdir|
        found_jar = libdir + "/" + jar
        return found_jar if FileTest::exists?(found_jar)
      }
    end
    
    def parameters_as_string
      result = []
      parameters.each {|key, value|
        result<<"-#{key}"
        result<<"-\"#{value}\""
      }
      result.join(" ")
    end
    
    def format_time (time)
      time.strftime("%Y%m%dT%H%M%S")
    end
    
    def parse_time (time)
      d = ParseDate::parsedate(time)
      Time.mktime(d[0], d[1], d[2], d[3], d[4], d[5])
    end
    
    def modifications (lastbuild_time, now)
      document = nil
      command_line = "java -cp #{classpath} #{bridge} #{sourcecontrol} #{parameters_as_string} -lastbuild #{format_time(lastbuild_time)} -now #{format_time(now)}"
      puts command_line
      IO.popen(command_line) {|result|
        document = REXML::Document.new(result)
      }
      
      modifications = Array.new
      document.elements.each("modification-set/modification"){|element|
        modification = Modification.new
        modification.type = element.attributes["type"]
        modification.revision = element.elements["revision"].text
        modification.modified_time = parse_time(element.elements["date"].text)
        modification.comment = element.elements["comment"].text
        modification.email_address = element.elements["email"].text
        modification.file_name = element.elements["filename"].text
        modification.folder_name = element.elements["project"].text
        modifications<<modification
      }
      
      modifications
    end
  end
  
  class Modification
    attr_accessor :type
    attr_accessor :modified_time
    attr_accessor :revision
    attr_accessor :comment
    attr_accessor :email_address
    attr_accessor :file_name
    attr_accessor :folder_name
  end
  
end
