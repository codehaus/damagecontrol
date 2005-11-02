require 'jabber4r/jabber4r'
require 'damagecontrol/publisher/base'

module DamageControl
  module Publisher
    class Jabber < Base
      attr_accessor :id_resource
      attr_accessor :password
      attr_accessor :friends
      
      def initialize
        @id_resource = "dcontrol"
        @password = "dcontrol"
        @friends = ""
      end

      def publish(build)
        session = nil
        begin
          session = login
          message = "#{build.revision.project.name}: #{build.state.description} build " + 
                    "(#{build.reason_description})"
          @friends.split(%r{,\s*}).each do |friend|
            begin
              session.new_message(friend).set_subject(message).set_body(message).send
            rescue Exception => e
              logger.error "Failed to send Jabber message to #{friend}" if logger
            end
          end
        ensure
          session.release if session
        end
      end
      
    private

      # Logs in and tries to register (and log in again) if login fails
      def login(register_if_login_fails=true)
        begin
          session = ::Jabber::Session.bind(@id_resource, @password)
        rescue
          if(register_if_login_fails)
            if(::Jabber::Session.register(@id_resource, @password))
              login(false)
            else
              raise "Failed to register #{@id_resource}"
            end
          end
        end
      end
    end
  end
end
