require 'damagecontrol/Clock'
require 'damagecontrol/Channel'

module DamageControl

  class Hub < Channel
    attr_accessor :clock

    def initialize
      super()
      @clock = Clock.new
    end
  end
  
end