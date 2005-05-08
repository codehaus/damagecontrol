require 'test/unit'
require 'rscm'
require 'rscm/generic_scm_tests'

module RSCM
  class PerforceTest < Test::Unit::TestCase
    include GenericSCMTests

    def create_scm(repository_root_dir, path = nil)
      p4 = Perforce.new
      p4.repository_root_dir = repository_root_dir
      p4
    end

    def test_shuld_create_new_client_only_if_it_does_not_already_exist
      work_dir = RSCM.new_temp_dir("use_existing_client")
      checkout_dir = "#{work_dir}/WorkingCopy"
      repository_dir = "#{work_dir}/repository"
      name = "client-one"

      scm = create_scm(repository_dir)
      scm.client_name = name
      scm.checkout_dir = checkout_dir

      scm.create_central
      @scm = scm
      import_damagecontrolled(scm, "#{work_dir}/damagecontrolled")
      assert(!scm.uptodate?(nil))

      other = create_scm(repository_dir)
      other.client_name = name
      other.checkout_dir = checkout_dir
      assert(!other.uptodate?(nil))
    end
  end
end