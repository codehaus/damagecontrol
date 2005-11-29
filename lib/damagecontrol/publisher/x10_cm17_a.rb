require 'x10/cm17a'

module DamageControl
  module Publisher
    class X10Cm17A < Base
      attr_reader :device
    
      def initialize
        @device = {}
        ::Build::STATES.each_with_index do |state, i|
          @device[state.name] = "a#{i+1}"
        end
      end

      def publish(build, x10=X10)
        exclusively_on(build.state, x10)
      end
      
    private

      # Turn on +device_on_attr+ and turn off all the others
      # We're sleeping one sec between them all. It seems necessary
      # To let the device cope with all the signals.
      def exclusively_on(on_state, x10)
        device_on_id = @device[on_state.name]
        x10.device(device_on_id).on
        sleep(1)

        device_off_ids = []
        Build::STATES.reject{|s| s.class.name == on_state.class.name}.each do |off_state|
          device_off_id = @device[off_state.name]
          unless(device_off_ids.include?(device_off_id))
            device_off_ids << device_off_id
            x10.device(device_off_id).off
            sleep(1)
          end
        end
      end
      
    end
  end
end