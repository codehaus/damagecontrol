require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/FileUtils'
require 'pebbles/Space'

class Object
  # override xmlserial to get rid of deprecation warning
  def make_type_element
    element = REXML::Element.new(self.class.to_s.gsub('::', '-'))
  end
end

module DamageControl

  class XMLPublisher < Pebbles::Space
  
    def initialize(channel, build_history_repository)
      super
      channel.add_consumer(self)
      @build_history_repository = build_history_repository
    end
  
    def on_message(message)
      if message.is_a? BuildCompleteEvent
        build = message.build
        build_history = @build_history_repository.history(build.project_name, build.dc_creation_time, true)
        xml_history_file = @build_history_repository.xml_history_file(build.project_name)
        File.open(xml_history_file, "w") do |f|
          build_history.to_xml.write(f, 2)
        end
      end
    end
  end

end
