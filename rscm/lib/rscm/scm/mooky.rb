require 'rscm/abstract_scm'

module RSCM
  class Mooky < AbstractSCM
    register self

    ann :description => "The Foo", :tip => "Foo is nonsense"
    attr_accessor :foo

    ann :description => "Le Bar", :tip => "Bar toi!"
    attr_accessor :bar
  
    def initialize(foo="", bar="chocolate bar")
    end
  
    def name
      "Mooky"
    end

  end
end
