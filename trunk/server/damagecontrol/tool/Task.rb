require 'damagecontrol/DamageControlServer'
require 'getoptlong'

module DamageControl

def symbol(string)
  if string=="" then return nil end
  if string.is_a? String then string.intern else string end
end

module ParseCommandLineOptions
  class CommandLineError < Exception
  end

  def parse_commandline
    begin
      opts_args = commandline_options.collect {|option| [ "--#{option}", GetoptLong::REQUIRED_ARGUMENT ] }
      
      opts = GetoptLong.new(*opts_args)
      
      raise CommandLineError.new(opts.error_message) if opts.error?
      
      required = commandline_required_options
      opts.each do |option, value|
        if option =~ /--(.*)/
          option = symbol($1)
          required.delete(option)
          self.send("#{option}=", value)
        else
          raise
        end
      end

      raise CommandLineError.new("Not all options specified: #{required.join(',')}") unless required == []
      
    rescue GetoptLong::InvalidOption => e
      commandline_error(e.message)
    rescue CommandLineError => e
      commandline_error(e.message)
    end
  end
  
  def commandline_error(message)
    puts "Error: #{message}"
    usage
    exit(3)
  end
  
  def usage
    puts "Usage: #{File.basename($0)} <options>"
    puts "Required options:"
    commandline_required_options.each do |option|
      puts "--#{option}"
    end
  end
  
  def commandline_required_options
    commandline_options.dup
  end
  
  def commandline_options
    self.class.commandline_options
  end
        
  class <<self
    def included(klass)
      class <<klass
        
        def commandline_options
          @commandline_options=[] unless defined?(@commandline_options)
          return @commandline_options + superclass.commandline_options if superclass.respond_to? "commandline_options"
          @commandline_options
        end
        
        def commandline_option(name, shortcut=nil, optionality=:required)
          @commandline_options=[] unless defined?(@commandline_options)
          @commandline_options << name
          attr_accessor(name)
        end
        
        def commandline_option?(command)
          build_commands.index(symbol(command))
        end
        
      end
    end
  end
end

class Task
  include ParseCommandLineOptions
  
  def initialize
    parse_commandline
  end
end

class ConfigTask < Task
  commandline_option :rootdir
  
  attr_reader :server
  
  def initialize
    super
    @server = DamageControlServer.new(:RootDir => rootdir)
    @server.init_config_services
  end
end

require 'xmlrpc/client'

class XMLRPCClientTask < Task
  commandline_option :url
  
  def xmlrpc_client(name)
    client = XMLRPC::Client.new2(url)
    client.proxy(name)
  end
  
end

end