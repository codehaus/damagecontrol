require 'damagecontrol/FileSystem'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/AsyncComponent'
require 'damagecontrol/tool/gnuplot/BuildHistoryReportGenerator'
require 'ftools'

module DamageControl

  class GraphPublisher < AsyncComponent
  
    attr_writer :filesystem

    def initialize(channel, target_base_dir, build_history_repository)
      super(channel)
      @filesystem = FileSystem.new
      @target_base_dir = target_base_dir
      @bhrg = DamageControl::Tool::Plot::BuildHistoryReportGenerator.new(build_history_repository)
    end
  
    def process_message(message)
      if message.is_a? BuildCompleteEvent
        build = message.build
        dir = "#{@target_base_dir}/#{build.project_name}"
        @filesystem.makedirs(dir)
        @bhrg.generate(@target_base_dir, build.project_name)
      end
    end
  end
end
