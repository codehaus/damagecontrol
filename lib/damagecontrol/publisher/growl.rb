require 'ruby-growl'

module DamageControl
  module Publisher
    class Growl < Base
      register self
    
      NOTIFICATION_TYPES = ["Build Successful", "Build Failed"] unless defined? NOTIFICATION_TYPES
    
      ann :description => "Hosts", :tip => "Comma-separated list of (OS X) hosts that will receive Growl notifications. Requires Growl 0.7 or later to be installed on these machines."
      attr_accessor :hosts

      def initialize
        @hosts = "localhost"
      end

      def name
        "Growl"
      end    

      def publish(build)
        index = nil
        message = "#{build.state.description} build\n(#{build.reason_description})"
        @hosts.split(%r{,\s*}).each do |host|
          begin
            g = ::Growl.new(host, "DamageControl (#{build.revision.project.name})", NOTIFICATION_TYPES)
            # A bug in Ruby-Growl (or Growl) prevents the message from being sticky.
            g.notify(NOTIFICATION_TYPES[build.successful? ? 0 : 1], build.revision.project.name, message, 0, true)
          rescue Exception => e
            Log.info("Growl publisher failed to notify #{host}: #{e.message}")
          end
        end
      end
    end
  end
end
