require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/FileUtils'
require 'pebbles/XSLT'
require 'pebbles/Space'

module DamageControl

  class StatsXSLTPublisher
    include XSLT  
  
    def initialize(channel, xsl_file_to_result_file_map)
      channel.add_consumer(self)
      @xsl_file_to_result_file_map = xsl_file_to_result_file_map
    end
  
    def put(message)
      if message.is_a? StatProducedEvent
        xml_file = message.xml_file
        
        @xsl_file_to_result_file_map.each do |xsl, filename|
          out = "#{File.dirname(xml_file)}/#{filename}"
          # yset 1 is a param to the stylesheet, indicating that we want the 1st set of ys.
          xslt(message.xml_file, xsl, out, "--param yset 1")
        end
      end
    end
  end

end
