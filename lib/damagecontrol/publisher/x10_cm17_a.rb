require 'x10/cm17a'

class Symbol
  def <=> (other)
    self.to_s <=> other.to_s
  end
end

module DamageControl
  module Publisher
    class X10Cm17A < Base
    
      @@device_attrs = {
        "Build::Broken"           => :broken, 
        "Build::Successful"       => :successful, 
        "Build::RepeatedlyBroken" => :repeatedly_broken, 
        "Build::Fixed"            => :fixed, 
        "Build::Executing"        => :executing
      }
      @@device_attrs.values.each{ |device_attr| attr_accessor device_attr }

      def publish(build, x10=X10)
        exclusively_on(@@device_attrs[build.state.class.name], x10)
      end
      
      def initialize
        @successful = @fixed = "a1"
        @broken = @repeatedly_broken = "a2"
        @executing = "a3"
      end

    private

      # Turin on +device_on_attr+ and turn off all the others
      # We're sleeping one sec between them all. It seems necessary
      # To let the device cope with all the signals.
      def exclusively_on(device_on_attr, x10)
        device_on_id = self.send(device_on_attr)
        x10.device(device_on_id).on
        sleep(1)

        off = []
        @@device_attrs.values.sort.reject{|a| a==device_on_attr}.each do |device_attr|
          device_id = self.send(device_attr)
          unless(device_id == device_on_id || off.include?(device_id))
            off << device_id
            x10.device(device_id).off
            sleep(1)
          end
        end
      end
      
    end
  end
end