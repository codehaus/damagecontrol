require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/FileUtils'
require 'pebbles/Space'
require 'cl/xmlserial'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/scm/Changes'
require 'damagecontrol/scm/CVS'
require 'damagecontrol/scm/SVN'
require 'damagecontrol/core/Build'

class Object
  # override xmlserial to get rid of deprecation warning
  def make_type_element
    element = REXML::Element.new(self.class.to_s.gsub('::', '-'))
  end
end

module DamageControl

  class XMLPublisher < Pebbles::Space
  
    def initialize(channel, project_directories, build_history_repository)
      super
      channel.add_consumer(self)
      @project_directories = project_directories
      @build_history_repository = build_history_repository
    end
  
    def on_message(message)
      if message.is_a? BuildCompleteEvent
        build = message.build
        dir = @project_directories.report_dir(build.project_name)
        FileUtils.mkpath(dir)
        build_history = @build_history_repository.history(build.project_name)
        build_history.to_xml.write($stdout, 2)
      end
    end
  end

end
