require 'rscm/abstract_scm'

module RSCM
  class Mooky < AbstractSCM
    attr_reader :foo
    attr_reader :bar
  
    def name
      "Mooky"
    end

    def form_file
      File.dirname(__FILE__) + "/form.html"
    end

  end
end
