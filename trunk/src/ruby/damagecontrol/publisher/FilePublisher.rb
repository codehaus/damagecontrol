require 'damagecontrol/FileSystem'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/AsyncComponent'
require 'ftools'

module DamageControl

  class FilePublisher < AsyncComponent
  
    attr_writer :filesystem

    def initialize(channel, target_base_dir, template)
      super(channel)
      @template = template
      @filesystem = FileSystem.new
      @target_base_dir = target_base_dir
    end
  
    def process_message(message)
      if message.is_a? BuildCompleteEvent
        build = message.build
        filepath = "#{@target_base_dir}/#{build.project_name}/#{build.timestamp}.#{@template.file_type}"
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
