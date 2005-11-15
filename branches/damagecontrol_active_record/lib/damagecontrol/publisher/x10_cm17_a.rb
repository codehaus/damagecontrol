require 'x10/cm17a'

class Symbol
  def <=> (other)
    self.to_s <=> other.to_s
  end
end

module DamageControl
  module Publisher
    class X10Cm17A < Base
    
      ::Build::STATES.each do |state|
        attr_sym = state.attr_sym("", "socket")
        attr_accessor attr_sym
      end

      def initialize
        i = 1
        ::Build::STATES.each do |state|
          instance_variable_set(state.attr_sym("@", "socket"), "a#{i}")
          i += 1
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
        device_on_id = instance_variable_get(on_state.attr_sym("@", "socket"))
        x10.device(device_on_id).on
        sleep(1)

        device_off_ids = []
        Build::STATES.reject{|s| s.class.name == on_state.class.name}.each do |off_state|
          device_off_id = instance_variable_get(off_state.attr_sym("@", "socket"))
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