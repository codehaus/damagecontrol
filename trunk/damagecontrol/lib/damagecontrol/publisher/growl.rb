require 'damagecontrol/publisher/base'
require 'ruby-growl'

module DamageControl
  module Publisher
    class Growl < Base
      register self
    
      NOTIFICATION_TYPES = ["Build Successful", "Build Failed"] unless defined? NOTIFICATION_TYPES
    
      ann :description => "Hosts", :tip => "Comma-separated list of (OS X) hosts that will receive Growl notifications. Requires Growl 0.6 or later."
      attr_reader :hosts

      def initialize
        @hosts = "localhost"
      end

      def name
        "Growl"
      end    

      def publish(build)
        message = nil
        index = nil
        if(build.successful?)
          message = "#{build.status_message} build (by #{build.changeset.developer})"
          index = 0
        else
          message = "#{build.changeset.developer} broke the build"
          index = 1
        end
        @hosts.split(%r{,\s*}).each do |host|
          begin
            g = ::Growl.new(host, "DamageControl (#{build.project.name})", NOTIFICATION_TYPES)
            # A bug in Ruby-Growl (or Growl) prevents the message from being sticky.
            g.notify(NOTIFICATION_TYPES[index], build.project.name, message, 0, true)
          rescue Exception => e
            Log.info("Growl publisher failed to notify #{host}: #{e.message}")
          end
        end
      end
    end
  end
end