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
        write_file(event.build)
      end
    end

  private

    def write_file(build_result)
      filedir = "#{@basedir}/#{build_result.label}"
      makedirs(filedir)

      filepath = "#{filedir}/#{@template.file_name}"
      invoke_template(filepath, build_result)
    end

    def makedirs(dir)
      File.makedirs(dir)
    end

    def invoke_template(filepath, build_result)
      file = File.new(filepath, "w")
      file.print(@template.generate(build_result))
      file.close
    end
      
  end
end