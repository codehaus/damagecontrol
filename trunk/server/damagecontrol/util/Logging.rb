require 'log4r'

module DamageControl
  
  module Logging
    @@logger = nil
    
    def init_logger
      @@logger = Log4r::Logger.new "DamageControl"
      @@logger.outputters = Log4r::Outputter.stdout
      
      # redefine accessor to increase performance
      Logging.module_eval <<-EOF
        def logger
          @@logger
        end
        module_function :logger
      EOF
    end
    module_function :init_logger
    
    def logger
      init_logger if @@logger.nil?
      @@logger
    end
    module_function :logger

    def debug
      logger.level = Log4r::DEBUG
    end
    module_function :debug
    
    def quiet
      logger.level = Log4r::INFO
    end
    module_function :quiet
    
    def silent
      logger.level = Log4r::FATAL
    end
    module_function :silent

  end
  
end