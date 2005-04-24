require 'test/unit'
require 'rscm/revision'

module RSCM
  module RevisionFixture
    def setup_changes
      #1
      @change1 = RSCM::RevisionFile.new("path/one", nil,   "jon",   "Fixed CATCH-22", nil, Time.utc(2004,7,5,12,0,2))
      @change2 = RSCM::RevisionFile.new("path/two", nil,   "jon",   "Fixed CATCH-22", nil, Time.utc(2004,7,5,12,0,4))
      #2
      @change3 = RSCM::RevisionFile.new("path/three", nil, "jon",   "hipp hurra", nil, Time.utc(2004,7,5,12,0,6))
      #3
      @change4 = RSCM::RevisionFile.new("path/four", nil,  "aslak", "hipp hurraX", nil, Time.utc(2004,7,5,12,0,8))
      #4
      @change5 = RSCM::RevisionFile.new("path/five", nil,  "aslak", "hipp hurra", nil, Time.utc(2004,7,5,12,0,10))
      @change6 = RSCM::RevisionFile.new("path/six", nil,   "aslak", "hipp hurra", nil, Time.utc(2004,7,5,12,0,12))
      @change7 = RSCM::RevisionFile.new("path/seven", nil, "aslak", "hipp hurra", nil, Time.utc(2004,7,5,12,0,14))
    end
  end
end
