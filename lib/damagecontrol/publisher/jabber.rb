require 'jabber4r/jabber4r'

module DamageControl
  module Publisher
    class Jabber < Base
      register self

      ann :description => "DamageControl Jabber Id/Resource"
      attr_accessor :id_resource

      ann :description => "DamageControl Jabber Password"
      attr_accessor :password

      ann :description => "DamageControl's Friends"
      attr_accessor :friends

      def initialize
        @id_resource = "damagecontrol@jabber.codehaus.org/damagecontrol"
        @friends = "aslak@jabber.codehaus.org"
      end
    
      def name
        "Jabber"
      end

      def publish(build)
        session = nil
        begin
          session = login
          message = nil
          if(build.successful?)
            message = "#{build.revision.project.name}: #{build.status_message} build (by #{build.revision.developer})"
          else
            message = "#{build.revision.project.name}: #{build.revision.developer} broke the build"
          end
          @friends.split(%r{,\s*}).each do |friend|
            begin
              session.new_message(friend).set_subject(message).set_body(message).send
            rescue Exception => e
              Log.error "Failed to send Jabber message to #{friend}"
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
