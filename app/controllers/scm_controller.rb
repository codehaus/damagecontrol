class ScmController < ApplicationController
  def list
    @scms = RSCM::Base.classes.collect{|cls| cls.new}
    @scm = @scms[0]
  end
end
