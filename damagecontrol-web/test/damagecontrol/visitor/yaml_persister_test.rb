require 'rubygems'
require_gem 'rscm'
require 'rscm/changes_fixture'
require 'rscm/tempdir'
require 'damagecontrol/visitor/yaml_persister'

module DamageControl
  module Visitor
    class YamlPersisterTest < Test::Unit::TestCase
      include RSCM::ChangesFixture

      def test_should_write_several_changesets_on_save_and_reload_them
        setup_changes
        changesets = RSCM::ChangeSets.new
        changesets.add(@change1)
        changesets.add(@change2)
        changesets.add(@change3)
        changesets.add(@change4)
        changesets.add(@change5)
        changesets.add(@change6)
        changesets.add(@change7)

        changesets_dir = RSCM.new_temp_dir("changesets")
        yp = YamlPersister.new(changesets_dir)

        changesets.accept(yp)

        latest_id = yp.latest_id
        all_reloaded = yp.load_upto(latest_id, 100)
        assert_equal(changesets, all_reloaded)

        some_reloaded = yp.load_upto("20040705120008", 2)
        assert_equal(2, some_reloaded.length)
        assert_equal(@change3, some_reloaded[0][0])
        assert_equal(@change4, some_reloaded[1][0])
      end

    end
  end
end