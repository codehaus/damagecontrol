require 'damagecontrol/AsyncComponent'
require 'damagecontrol/BuildBootstrapper'

module DamageControl

  class BuildBootstrapperComponent < AsyncComponent
    
    def initialize(hub, basedir)
      super(hub)
      @basedir = File.expand_path(basedir)
      @bootstrapper = BuildBootstrapper.new
      puts "My basedir is #{@basedir}"
    end

    def process_message(message)
      if (message.is_a?(SocketRequestEvent))
        build = @bootstrapper.bootstrap_build(message.payload, @basedir)
        hub.publish_message(BuildRequestEvent.new(build))
      end
      consume_message(message)
    end

  end
end