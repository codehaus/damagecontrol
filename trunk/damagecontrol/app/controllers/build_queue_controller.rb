require 'yaml'

class BuildQueueController < ApplicationController

  layout nil

  # Renders the build queue:
  # #TODO: use html layers for the progress bar!
  # | **** (3 min left)   Foo   |
  # | **   (38 sec left)  Bar   |
  # |                     Zap   |
  # |                     Pie   |
  def view
    @queue = []
    if(File.exist?("#{BASEDIR}/build_queue.yaml")) 
      File.open("#{BASEDIR}/build_queue.yaml") do |io|
        @queue = YAML::load(io)
      end
    end
  end
end
