require 'test/unit'
require 'rscm/changes'
require 'rscm/mockit'

module Test
  module Unit
    class TestCase
      include MockIt

      def setup
        MockIt::setup
        #1
        @change1 = RSCM::Change.new("path/one",   "jon",   "Fixed CATCH-22", "1.1", Time.utc(2004,7,5,12,0,2))
        @change2 = RSCM::Change.new("path/two",   "jon",   "Fixed CATCH-22", "1.2", Time.utc(2004,7,5,12,0,4))
        #2
        @change3 = RSCM::Change.new("path/three", "jon",   "hipp hurra",  "1.3", Time.utc(2004,7,5,12,0,6))
        #3
        @change4 = RSCM::Change.new("path/four",  "aslak", "hipp hurraX", "1.4", Time.utc(2004,7,5,12,0,8))
        #4
        @change5 = RSCM::Change.new("path/five",  "aslak", "hipp hurra",  "1.5", Time.utc(2004,7,5,12,0,10))
        @change6 = RSCM::Change.new("path/six",   "aslak", "hipp hurra",  "1.6", Time.utc(2004,7,5,12,0,12))
        @change7 = RSCM::Change.new("path/seven", "aslak", "hipp hurra",  "1.7", Time.utc(2004,7,5,12,0,14))
      end

    end
  end
end
