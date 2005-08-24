require 'rscm/base'

module RSCM
  class Mooky < Base
    #register self

    ann :description => "The Foo", :tip => "Foo is nonsense"
    attr_accessor :foo

    ann :description => "Le Bar", :tip => "Bar toi!"
    attr_accessor :bar
  
    def initialize(foo="", bar="chocolate bar")
    end
  
  end
end
