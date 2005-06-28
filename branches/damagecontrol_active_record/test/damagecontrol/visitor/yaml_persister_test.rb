require 'rubygems'
require 'rscm/revision_fixture'
require 'rscm/tempdir'
require 'damagecontrol/visitor/yaml_persister'

module DamageControl
  module Visitor
    class YamlPersisterTest < Test::Unit::TestCase
      include RSCM::RevisionFixture

      def test_should_write_several_revisions_on_save_and_reload_them
        setup_changes
        revisions = RSCM::Revisions.new
        revisions.add(@change1)
        revisions.add(@change2)
        revisions.add(@change3)
        revisions.add(@change4)
        revisions.add(@change5)
        revisions.add(@change6)
        revisions.add(@change7)

        revisions_dir = RSCM.new_temp_dir("revisions")
        yp = YamlPersister.new(revisions_dir)

        revisions.accept(yp)

        latest_identifier = yp.latest_identifier
        assert_equal(Time.utc(2004,7,5,12,0,14), latest_identifier)
        all_reloaded = yp.load_upto(latest_identifier, 100)
        assert_equal(revisions, all_reloaded)

        some_reloaded = yp.load_upto(Time.utc(2004,7,5,12,0,14), 2)
        assert_equal(2, some_reloaded.length)
        assert_equal(@change4, some_reloaded[0][0])
        assert_equal(@change6, some_reloaded[1][1])
      end

    end
  end
end