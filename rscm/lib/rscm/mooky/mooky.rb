require 'rscm/abstract_scm'

module RSCM
  class Mooky < AbstractSCM
    attr_accessor :foo
    attr_accessor :bar
  
    def name
      "Mooky"
    end

  end
end
