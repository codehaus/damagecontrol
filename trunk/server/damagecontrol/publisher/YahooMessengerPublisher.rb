require 'jabber4r/jabber4r'
require 'damagecontrol/util/Timer'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/FileUtils'
require 'pebbles/Space'

module DamageControl

  class YahooMessengerPublisher < Pebbles::Space
  
    include FileUtils
  
    attr_accessor :jabber
    attr_reader :channel
    attr_reader :username
    attr_reader :password
    attr_reader :template
  
    def initialize(channel, template, username, password)
      super(channel)
      @username = username
      @password = password
      @template = template
    end
  
    def on_message(message)
      if message.is_a?(BuildCompleteEvent)
        build = message.build
        
        content = template.generate(build)
        recipients(build).each do |recipient|
          send_message_to_recipient(recipient, content)
        end
        
      end
    end
    
    def recipients(build)
      ["jon_tirsen", "joejoejoewalnes", "aslak_hellesoy"]
    end

    def send_message_to_recipient(recipient, content)
      exec_groovy_script("#{damagecontrol_home}/server/damagecontrol/publisher/SendYahooMessage.groovy", username, password, recipient, content)
    end
    
    def path_separator
      if windows? then ";" else ":" end
    end
    
    def jar_dir
      "#{damagecontrol_home}/server/jars"
    end
    
    def classpath
      Dir["#{jar_dir}/*.jar"].join(path_separator)
    end
    
    def java_executable
      "java"
    end
    
    def exec_groovy_script(script, *args)
      system(java_executable, "-classpath", classpath, "groovy.lang.GroovyShell", script, *args)
    end
    
  end
  
end

