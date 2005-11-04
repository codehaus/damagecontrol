require 'rscm/base'

module RSCM
  class Mooky < Base
    attr_accessor :foo
    attr_accessor :bar
  
    def initialize(foo="", bar="chocolate bar")
    end
  
  end
end
