require 'stringio'
require 'rscm/changes_fixture'
require 'rscm/tempdir'
require 'damagecontrol/project'
require 'damagecontrol/visitor/diff_persister'

module DamageControl
  module Visitor
    class DiffPersisterTest < Test::Unit::TestCase
      include RSCM::ChangesFixture

      class MockSCM
        def initialize(diffs)
          @diffs = diffs
          @n = 0
        end
        
        def diff(checkout_dir, change, &proc)
          proc.call(@diffs[@n])
          @n = @n + 1
        end
      end

      def test_should_persist_diff_for_each_change
        project_dir = RSCM.new_temp_dir("DiffPersisterTest")
        project = ::DamageControl::Project.new
        project.dir = project_dir

        setup_changes
        changeset = RSCM::ChangeSet.new
        changeset << @change1
        changeset << @change2
        changeset.project = project

        diff1 = "This\ris\na\r\ndiff for 1"
        diff2 = "This\ris\na\r\ndiff for 2"

        scm = MockSCM.new([diff1, diff2])
        project.scm = scm
        dp = DiffPersister.new

        changeset.accept(dp)
        assert_equal(diff1, File.open("#{project_dir}/changesets/20040705120004/diffs/path/one.diff").read)
        assert_equal(diff2, File.open("#{project_dir}/changesets/20040705120004/diffs/path/two.diff").read)

      end

    end
  end
end