require 'rscm/changes_fixture'
require 'rscm/visitor/diff_persister'
require 'stringio'
require 'rscm/tempdir'

module RSCM
  module Visitor
    class DifferTest < Test::Unit::TestCase

      class MockSCM
        def initialize(checkout_dir, diffs)
          @checkout_dir, @diffs = checkout_dir, diffs
          @n = 0
        end
        
        def diff(checkout_dir, change, &proc)
          proc.call(@diffs[@n])
          @n = @n + 1
        end
      end

      def test_should_persist_diff_for_each_change
        basedir = RSCM.new_temp_dir
        ENV["RSCM_BASE"] = basedir

        changesets = RSCM::ChangeSets.new
        changesets.add(@change1)
        changesets.add(@change2)
        changesets.add(@change3)

        diff1 = "This\ris\na\r\ndiff for 1"
        diff2 = "This\ris\na\r\ndiff for 2"
        diff3 = "This\ris\na\r\ndiff for 3"

        scm = MockSCM.new("#{basedir}/mooky/checkout", [diff1, diff2, diff3])
        dp = DiffPersister.new(scm, "mooky")

        changesets.accept(dp)
        assert_equal(diff1, File.open("#{basedir}/mooky/changesets/20040705120004/path/one.diff").read)
        assert_equal(diff2, File.open("#{basedir}/mooky/changesets/20040705120004/path/two.diff").read)
        assert_equal(diff3, File.open("#{basedir}/mooky/changesets/20040705120006/path/three.diff").read)

      end

    end
  end
end