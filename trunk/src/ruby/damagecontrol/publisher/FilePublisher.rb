require 'damagecontrol/FileSystem'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/AsyncComponent'
require 'ftools'

# content (template)
# dir location (this)
# filename (template)

module DamageControl

  class FilePublisher < AsyncComponent

    def initialize(hub, basedir, template, filesystem=FileSystem.new)
      super(hub)
      @basedir = basedir
      @template = template
      @filesystem = filesystem
    end
  
    def process_message(event)
      if event.is_a? BuildCompleteEvent
        filedir = "#{@basedir}/#{event.build.label}"
        @filesystem.makedirs(filedir)

        filepath = "#{filedir}/#{@template.file_name}"
        content = @template.generate(event.build)
        file = @filesystem.newFile(filepath, "w")
        file.print(content)
        file.close
      end
    end
  end
end