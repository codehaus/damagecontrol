require 'rscm/abstract_scm'

module RSCM
  class Mooky < AbstractSCM
    attr_accessor :foo
    attr_accessor :bar
  
    def name
      "Mooky"
    end

    def form_file
      File.dirname(__FILE__) + "/form.html"
    end

  end
end
