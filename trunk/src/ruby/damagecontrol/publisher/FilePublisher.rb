require 'damagecontrol/FileSystem'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/AsyncComponent'
require 'ftools'

# content (template)
# dir location (this)
# filename (template)

module DamageControl

  class FilePublisher < AsyncComponent

    def initialize(hub, template, filesystem=FileSystem.new)
      super(hub)
      @template = template
      @filesystem = filesystem
    end
  
    def process_message(message)
      if message.is_a? BuildCompleteEvent
        filepath = "#{message.build.reports_dir}/#{@template.file_name(message.build)}"
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