module DamageControl
  module Process

    # Base class for processes
    class Base
      cattr_accessor :logger
      
      # Yields projects one by one - forever. Sleeps +interval+
      # seconds (or less) between each round.
      def forever(interval=30)
        at_exit do
          logger.info "#{self.class.name.demodulize} exiting" if logger
        end

        logger.info "#{self.class.name.demodulize} builder started" if logger
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
                logger.error "Couldn't handle project #{project.name}. Unexpected error: #{e.message}"
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