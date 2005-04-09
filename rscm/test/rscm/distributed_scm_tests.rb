module RSCM
  module DistributedSCMTests
    def test_should_identify_as_distributed
      work_dir = RSCM.new_temp_dir("distributed")
      repository_dir = "#{work_dir}/repository"
      scm = create_scm(repository_dir, "damagecontrolled")
      scm.create
      
      assert(scm.distributed?)
    end

    def test_should_create_local_repository

    end
    
    def test_should_pull_before_checkout

    end
  end
end
