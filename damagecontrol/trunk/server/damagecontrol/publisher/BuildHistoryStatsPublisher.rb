require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/FileUtils'
require 'pebbles/Space'
require 'pebbles/XSLT'

class Object
  # override xmlserial to get rid of deprecation warning
  def make_type_element
    element = REXML::Element.new(self.class.to_s.gsub('::', '-'))
  end
end

module DamageControl

  class BuildHistoryStatsPublisher
    include XSLT
    include FileUtils

    def initialize(channel, build_history_repository)
      @channel = channel
      @channel.add_consumer(self)
      @build_history_repository = build_history_repository
    end
  
    def put(message)
      if message.is_a? BuildCompleteEvent
        build = message.build
        build_history = @build_history_repository.history(build.project_name, false)
        xml_history_file = "#{@build_history_repository.project_dir(build.project_name)}/build/build_history.xml"
        mkdir_p(File.dirname(xml_history_file))
        File.open(xml_history_file, "w") do |f|
          build_history.to_xml.write(f, 2)
        end
        stats_file = "#{@build_history_repository.project_dir(build.project_name)}/stats/build_history_stats.xml"
        mkdir_p(File.dirname(stats_file))
        xslt(xml_history_file, "#{damagecontrol_home}/server/damagecontrol/publisher/build_history_to_stats.xsl", stats_file)
        @channel.put(StatProducedEvent.new(build.project_name, stats_file))
      end
    end
  end

end
