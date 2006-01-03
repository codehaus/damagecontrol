require 'rubygems'
require 'cmdparse'
require File.dirname(__FILE__) + '/../version'

module DamageControl
  module Process

    class Command < CmdParse::Command
      def initialize(name, processes)
        super(name, false)
        ENV['RAILS_ENV'] = 'production'
        @processes = processes
        
        self.options = CmdParse::OptionParserWrapper.new do |opts|
          opts.on("-e", "--environment=name", String,
                  "Specifies the environment (test|development|production).",
                  "Default: #{ENV['RAILS_ENV']}") { |ENV['RAILS_ENV']|}
        end
      end
      
      def execute(args)
        @processes.each_with_index do |process, i|
          if(i < @processes.size-1)
            pid = fork do
              process.init
              process.run
            end
            at_exit do
              ::Process.wait(pid)
            end
            needs_fork = true
          else
            process.init
            process.run
          end
        end
      end
    end

    # Base class for processes
    class Base
      attr_accessor :logger

      def init
        require File.dirname(__FILE__) + '/../../../config/environment'

        logfile = "#{DC_DATA_DIR}/log/#{self.class.name.demodulize.underscore}.log"
        puts logfile
        $DC_LOGGER = Logger.new(logfile, 10, 1.megabyte)
        $DC_LOGGER.datetime_format = "%Y-%m-%d %H:%M:%S"
        $DC_LOGGER.level = Logger::DEBUG
        @logger = $DC_LOGGER
      end
      
      # Yields projects one by one - forever. Sleeps +interval+
      # seconds (or less) between each round.
      def forever(interval=30)
        begin
          loop do
            start = Time.now
            projects = []
            begin
              projects = Project.find(:all)
            rescue Exception => e
              logger.error "Unexpected error: #{e.message}"
              logger.error e.backtrace.join("\n")
            end

            projects.each do |project|
              begin
                project.reload
                yield project
              rescue ActiveRecord::RecordNotFound => e
                logger.error "Couldn't handle project #{project.name}. It looks like it was recently deleted"
              rescue Exception => e
                logger.error "Couldn't handle project #{project.name}. Unexpected error: #{e.message} (#{e.class.name})"
                logger.error e.backtrace.join("\n")
              end
            end

            duration = Time.now - start
            sleeptime = interval - duration
            sleep sleeptime unless sleeptime <= 0
          end
        rescue SignalException => e
          logger.info "#{self.class.name.demodulize} received signal to shut down"
          exit!(1)
        end
      end
    end
  end
end