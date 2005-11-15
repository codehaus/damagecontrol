require 'ruby-growl'
require 'damagecontrol/publisher/base'

module DamageControl
  module Publisher
    class Growl < Base
      attr_accessor :hosts

      def initialize
        @hosts = "localhost"
      end

      def publish(build)
        @hosts.split(%r{,\s*}).each do |host|
          app = "DamageControl (#{build.revision.project.name})"
          g = ::Growl.new(
            host, 
            app, 
            ::Build::STATES.collect{|state| state.name}
          )

          message = "#{build.state.name} build\n(#{build.reason_description})"
          g.notify(build.state.name, build.revision.project.name, message, 0, false)
        end
      end
    end
  end
end
