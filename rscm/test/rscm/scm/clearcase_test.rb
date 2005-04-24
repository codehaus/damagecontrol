require 'test/unit'
require 'rscm/generic_scm_tests'
require 'rscm/clearcase/clearcase'

module RSCM
  class ClearCaseTest < Test::Unit::TestCase

    def setup
      @checkout_dir = "C:\\ClearCase_Storage\\viewroot\\icah_CorpAsstPlan_integration\\merchandising\\MerchandisingRandD"
    end

    def test_revisions
      scm = ClearCase.new
      revisions = scm.revisions(@checkout_dir, Time.utc(2005,03,03,0,0,0))
    end

    def Xtest_checkout
      # delete some local files (so we get some checkouts!)
      build_xml = "build.xml"
      actions_xml = "JavaSource/actions.xml"
      File.delete("#{checkout_dir}/#{build_xml}") if File.exist?("#{checkout_dir}/#{build_xml}")
      File.delete("#{checkout_dir}/#{actions_xml}") if File.exist?("#{checkout_dir}/#{actions_xml}")

      scm = ClearCase.new

      assert(!scm.uptodate?(@checkout_dir, Time.new.utc))
      assert(!scm.uptodate?(@checkout_dir, Time.new.utc))

      yielded_files = []
      files = scm.checkout(@checkout_dir) do |file_name|
        yielded_files << file_name
      end

      assert_equal(files, yielded_files)
      assert_equal([build_xml, actions_xml], files)
    end
  
  end
end
