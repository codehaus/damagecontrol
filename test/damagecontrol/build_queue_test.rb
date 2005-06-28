require 'test/unit'
require 'rscm/mockit'
require 'damagecontrol/build_queue'
require 'damagecontrol/revision_ext'

module DamageControl
  class BuildQueueTest < Test::Unit::TestCase
    include MockIt
    
    def setup
      @fred = Project.new("FRED")
      @fred_cs_1 = RSCM::Revision.new
      @fred_cs_1.project = @fred
      @fred_cs_2 = RSCM::Revision.new
      @fred_cs_2 << RSCM::RevisionFile.new
      @fred_cs_2.project = @fred
 
      @wilma = Project.new("WILMA")
      @wilma_cs_1 = RSCM::Revision.new
      @wilma_cs_1.project = @wilma

      @barney = Project.new("BARNEY")
      @barney_cs_1 = RSCM::Revision.new
      @barney_cs_1.project = @barney

      @dino = Project.new("DINO")
      @dino_cs_1 = RSCM::Revision.new
      @dino_cs_1.project = @dino
    end

    def test_should_report_build_queue
      bs = BuildQueue.new
      bs.enqueue(@fred_cs_1, "foo")
      assert_equal([@fred_cs_1], bs.queue.collect{|req| req.revision})
    end
    
    def test_should_reschedule_revision_of_equal_project
      bs = BuildQueue.new
      bs.enqueue(@fred_cs_1, "foo")
      bs.enqueue(@wilma_cs_1, "bar")
      bs.enqueue(@fred_cs_2, "zap")
      assert_equal([@fred_cs_2, @wilma_cs_1], bs.queue.collect{|req| req.revision})
      assert_equal(["zap"], bs.queue[0].reasons)
    end

    def test_should_accumulate_reasons_when_revision_is_enqueued_several_times
      bs = BuildQueue.new
      bs.enqueue(@fred_cs_1, "foo")
      bs.enqueue(@fred_cs_1, "bar")
      request = bs.queue[0]
      assert_equal(@fred_cs_1, request.revision)
      assert_equal(["foo", "bar"], request.reasons)
    end
    
    def test_should_schedule_builds_according_to_dependencies
      # F->D->W->B
      @fred.add_dependency(@dino)
      @dino.add_dependency(@wilma)
      @wilma.add_dependency(@barney)
    
      # 3       F
      # 2     F D
      # 1   F W W
      # 0 W W B B
      bs = BuildQueue.new

      bs.enqueue(@wilma_cs_1, nil)
      projects = bs.queue.collect{|req| req.revision.project.name}
      assert_equal(["WILMA"], projects)

      bs.enqueue(@fred_cs_1, nil)
      projects = bs.queue.collect{|req| req.revision.project.name}
      assert_equal(["WILMA", "FRED"], projects)

      bs.enqueue(@barney_cs_1, nil)
      projects = bs.queue.collect{|req| req.revision.project.name}
      assert_equal(["BARNEY", "WILMA", "FRED"], projects)

      bs.enqueue(@dino_cs_1, nil)
      projects = bs.queue.collect{|req| req.revision.project.name}
      assert_equal(["BARNEY", "WILMA", "DINO", "FRED"], projects)
    end
    
    def test_should_create_hash_structure_for_persistence
      @fred.add_dependency(@dino)

      bs = BuildQueue.new
      bs.enqueue(@fred_cs_1, "fred is cool")
      bs.enqueue(@dino_cs_1, "dino is cool")
      
      hash = [
        {:project_name => "DINO", :reasons => ["dino is cool"], :building => false},
        {:project_name => "FRED", :reasons => ["fred is cool"], :building => false}
      ]
      
      assert_equal(hash, bs.as_list)
    end
    
    def test_should_move_pending_to_building
      bs = BuildQueue.new
      bs.enqueue(@fred_cs_1, "fred is cool")
      bs.enqueue(@dino_cs_1, "dino is cool")
      
      assert_equal([
          {:project_name => "FRED", :reasons => ["fred is cool"], :building => false},
          {:project_name => "DINO", :reasons => ["dino is cool"], :building => false}
        ], 
        bs.as_list
      )

      req = bs.pop(nil)
      assert_equal("FRED", req.revision.project.name)
      assert_equal([
          {:project_name => "FRED", :reasons => ["fred is cool"], :building => true},
          {:project_name => "DINO", :reasons => ["dino is cool"], :building => false}
        ], 
        bs.as_list
      )

      # make sure already building ones doesn't affect queue
      bs.enqueue(@fred_cs_2, "fred is cool")
      assert_equal([
          {:project_name => "FRED", :reasons => ["fred is cool"], :building => true},
          {:project_name => "DINO", :reasons => ["dino is cool"], :building => false},
          {:project_name => "FRED", :reasons => ["fred is cool"], :building => false}
        ], 
        bs.as_list
      )

      bs.delete(req)
      assert_equal([
          {:project_name => "DINO", :reasons => ["dino is cool"], :building => false},
          {:project_name => "FRED", :reasons => ["fred is cool"], :building => false}
        ], 
        bs.as_list
      )
    end
  end
end
