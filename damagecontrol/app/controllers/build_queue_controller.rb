require 'yaml'

class BuildQueueController < ApplicationController

  layout nil

  # Renders the build queue:
  #
  # | *** (3 min)  Foo   |
  # | ** (38 sec)  Bar   |
  # |              Zap   |
  # |              Pie   |
  def view
    @queue = []
    if(File.exist?("#{BASEDIR}/build_queue.yaml")) 
      File.open("#{BASEDIR}/build_queue.yaml") do |io|
        @queue = YAML::load(io)
      end
    end
    $stderr.puts @queue.inspect
  end
end
