require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/FileUtils'
require 'pebbles/Space'
require 'damagecontrol/tool/gnuplot/BuildHistoryReportGenerator'
require 'ftools'

module DamageControl

  class GraphPublisher < Pebbles::Space
  
    def initialize(channel, project_directories, build_history_repository)
      super
      channel.add_consumer(self)
      @project_directories = project_directories
      @bhrg = DamageControl::Tool::Plot::BuildHistoryReportGenerator.new(build_history_repository)
    end
  
    def on_message(message)
      if message.is_a? BuildCompleteEvent
        build = message.build
        dir = @project_directories.report_dir(build.project_name)
        FileUtils.mkpath(dir)
        @bhrg.generate(dir, build.project_name)
      end
    end
  end

end
