require 'log4r'

module DamageControl
  
  module Logging
  
    ROOT_LOGGER_NAME = "DamageControl"
    
    @@logging_initialized = false
    
    def init_logging(config_file = nil, params = {})
      @@logging_initialized = true
      
      # uncomment to debug Log4r configuration
      #Log4r::Logger.new("log4r").outputters = Log4r::Outputter.stdout
      
      if config_file.nil?
        Log4r::Logger.new(ROOT_LOGGER_NAME)
        root_logger.outputters = Log4r::Outputter.stdout
      else
        require 'log4r/configurator'
        require 'log4r/outputter/emailoutputter'
        
        # set any runtime XML variables
        params.each {|key, value| Log4r::Configurator[key] = value }
        # Load up the config file
        Log4r::Configurator.load_xml_file(config_file)
      end
    end
    module_function :init_logging
    
    def root_logger
      init_logging unless @@logging_initialized
      
      Log4r::Logger[ROOT_LOGGER_NAME]
    end
    module_function :root_logger
    
    def default_logger_name
      self.class.to_s
    end
    
    def logger(name=default_logger_name)
      init_logging unless @@logging_initialized
      Log4r::Logger.new(name) if Log4r::Logger[name].nil?
      Log4r::Logger[name]
    end

    def debug
      root_logger.level = Log4r::DEBUG
    end
    module_function :debug
    
    def quiet
      root_logger.level = Log4r::INFO
    end
    module_function :quiet
    
    def silent
      root_logger.level = Log4r::FATAL
    end
    module_function :silent
    
    def format_exception(e)
      e.message + "\n\t" + e.backtrace.join("\n\t")
    end

  end
  
end