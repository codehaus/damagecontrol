require 'test/unit'
require 'rscm/changes'

module RSCM
  module ChangesFixture
    def setup_changes
      #1
      @change1 = RSCM::Change.new("path/one",   "jon",   "Fixed CATCH-22", nil, Time.utc(2004,7,5,12,0,2))
      @change2 = RSCM::Change.new("path/two",   "jon",   "Fixed CATCH-22", nil, Time.utc(2004,7,5,12,0,4))
      #2
      @change3 = RSCM::Change.new("path/three", "jon",   "hipp hurra", nil, Time.utc(2004,7,5,12,0,6))
      #3
      @change4 = RSCM::Change.new("path/four",  "aslak", "hipp hurraX", nil, Time.utc(2004,7,5,12,0,8))
      #4
      @change5 = RSCM::Change.new("path/five",  "aslak", "hipp hurra", nil, Time.utc(2004,7,5,12,0,10))
      @change6 = RSCM::Change.new("path/six",   "aslak", "hipp hurra", nil, Time.utc(2004,7,5,12,0,12))
      @change7 = RSCM::Change.new("path/seven", "aslak", "hipp hurra", nil, Time.utc(2004,7,5,12,0,14))
    end
  end
end
