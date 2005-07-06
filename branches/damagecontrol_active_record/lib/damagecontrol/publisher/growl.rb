require 'ruby-growl'
require 'damagecontrol/publisher/base'

module DamageControl
  module Publisher
    class Growl < Base
      register self
    
      ann :description => "Hosts"
      ann :tip => "Comma-separated list of (OS X) hosts that will receive Growl notifications. " + 
                  "Growl 0.7 or later must be installed on these hosts."
      attr_accessor :hosts

      def initialize
        @hosts = "localhost"
      end

      def name
        "Growl"
      end    

      def publish(build)
        @hosts.split(%r{,\s*}).each do |host|
          begin
            g = ::Growl.new(
              host, 
              "DamageControl (#{build.revision.project.name})", 
              ::Build::STATES.collect{|state| state.description}
            )

            message = "#{build.state.description} build\n(#{build.reason_description})"
            # A bug in Ruby-Growl (or Growl) prevents the message from being sticky (last parameter).
            g.notify(build.state.description, build.revision.project.name, message, 0, true)
          rescue Exception => e
            logger.error("Growl publisher failed to notify #{host}: #{e.message}") if logger
          end
        end
      end
    end
  end
end
