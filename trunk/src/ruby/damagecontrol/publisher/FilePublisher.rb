require 'damagecontrol/FileSystem'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/AsyncComponent'
require 'ftools'

# content (template)
# dir location (this)
# filename (template)

module DamageControl

  class FilePublisher < AsyncComponent
  
    attr_writer :filesystem

    def initialize(channel, template)
      super(channel)
      @template = template
      @filesystem = FileSystem.new
    end
  
    def process_message(message)
      if message.is_a? BuildCompleteEvent
        filepath = "#{message.build.absolute_reports_path}/#{@template.file_name(message.build)}"
        @filesystem.makedirs(File.dirname(filepath))

        content = @template.generate(message.build)
        file = @filesystem.newFile(filepath, "w")
        file.print(content)
        file.flush
        file.close
      end
    end
  end
end
