require 'logger'

module DamageControl
  
  module Logging
    @@logger = nil
    
    def init_logger
      @@logger = Logger.new(STDOUT)
      
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

    def quiet
      logger.level = Logger::Severity::INFO
    end
    module_function :quiet
    
    def silent
      logger.level = Logger::Severity::FATAL
    end
    module_function :silent

  end
  
end