require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/core/AsyncComponent'
require 'damagecontrol/tool/gnuplot/BuildHistoryReportGenerator'
require 'ftools'

module DamageControl

  class GraphPublisher < AsyncComponent
  
    def initialize(channel, target_base_dir, build_history_repository)
      super(channel)
      @target_base_dir = target_base_dir
      @bhrg = DamageControl::Tool::Plot::BuildHistoryReportGenerator.new(build_history_repository)
    end
  
    def process_message(message)
      if message.is_a? BuildCompleteEvent
        build = message.build
        dir = "#{@target_base_dir}/#{build.project_name}"
        FileUtils.mkpath(dir)
        @bhrg.generate(dir, build.project_name)
      end
    end
  end

end
