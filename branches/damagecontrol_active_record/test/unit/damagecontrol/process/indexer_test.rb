require File.dirname(__FILE__) + '/../../../test_helper'
require 'rscm/mockit'
require 'stringio'

module DamageControl
  module Process
    class IndexerTest < Test::Unit::TestCase

      class FakeScm
        attr_writer :checkout_dir
        attr_writer :enabled
      
        @@contents = {
          "contains/juice.rb" => "what juice do you like?",
          "contains/milk.rb" => "is milk good for dogs?",
          "contains/wine.rb" => "should i feed my husband wine?"
        }
      
        def open(revision_file, &block)
          yield StringIO.new(@@contents[revision_file.path])
        end
      end
    
      def test_should_index_files
        return
        scm = FakeScm.new
      
        p = Project.create(:name => "pp", :scm => scm)
      
        r = RSCM::Revision.new
        r << RSCM::RevisionFile.new("contains/juice.rb", RSCM::RevisionFile::ADDED)
        r << RSCM::RevisionFile.new("contains/milk.rb", RSCM::RevisionFile::ADDED)
        r << RSCM::RevisionFile.new("contains/wine.rb", RSCM::RevisionFile::ADDED)

#        revisions = Indexer.new.persist_revisions(p, [r])
#        Revision.index!(revisions)
#      
#        files = RevisionFile.find_by_contents("milk")
#      
#        assert_equal 1, files.length
#        assert_equal "contains/milk.rb", files[0].path
      end

    end
  end
end