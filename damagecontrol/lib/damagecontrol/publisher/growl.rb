require 'damagecontrol/publisher/base'
require 'ruby-growl'

module DamageControl
  module Publisher
    class Growl < Base
      register self
    
      ann :description => "Hosts", :tip => "Comma-separated list of (OS X) hosts that will receive Growl notifications. Requires Growl 0.6 or later."
      attr_reader :hosts

      def initialize
        @hosts = "localhost"
      end

      def name
        "Growl"
      end    

      def publish(build)
        status_message = build.successful? "Successful" : "Failed. Process exit code: #{build.exit_code}"
        hosts = @hosts.split(%r{,\s*})
        hosts.each do |host|
          begin
            g = ::Growl.new("localhost", "DamageControl", ["DamageControl Notification"])
            g.notify("DamageControl Notification", "#{build.project.name}", "Build #{status_message}", 0, true)
          rescue Exception => e
            Log.info("Growl publisher failed to notify #{host}: #{e.message}")
          end
        end
      end
    end
  end
end