require 'damagecontrol/BuildEvents'
require 'damagecontrol/AsyncComponent'
require 'ftools'

# content (template)
# dir location (this)
# filename (template)

module DamageControl

  class FilePublisher < AsyncComponent

    def initialize(hub, basedir, template)
      super(hub)
      @basedir = basedir
      @template = template
    end
  
    def process_message(event)
      if event.is_a? BuildCompleteEvent
        filedir = "#{@basedir}/#{event.build.label}"
        makedirs(filedir)

        filepath = "#{filedir}/#{@template.file_name}"
        content = @template.generate(event.build)
        write_to_file(filepath, content)
      end
    end

  private

    def write_file(build_result)

      write_to_file(file, content)
    end

    def makedirs(dir)
      File.makedirs(dir)
    end

    def write_to_file(filepath, content)
      File.new(filepath, "w")
      file.print(content)
      file.close
    end
      
  end
end