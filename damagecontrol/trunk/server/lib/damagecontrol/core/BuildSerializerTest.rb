require 'test/unit'
require 'yaml'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildSerializer'
require 'rubygems'
require 'rscm'

module DamageControl

  class BuildSerializerTest < Test::Unit::TestCase
    include FileUtils

    def setup
      @b = Build.new("jalla")
      @b.dc_creation_time = Time.utc(1971,2,28,23,45,01)
      @b.dc_start_time = Time.utc(1971,2,28,23,45,07)
      @b.scm_commit_time = Time.utc(1971,2,28,23,45,02)
      @b.duration = 123
      @b.status = Build::BUILDING
      @b.label = "mooky"
      @b.changesets = RSCM::ChangeSets.new
      
      # Benchmark:
      # 1 Changesets with 3 files : YAML speed is same as custom
      # 2 Changesets with 3 files : YAML speed is 1.2 of custom
      # 4 Changesets with 3 files : YAML speed is 2.2 of custom
      # 2 Changesets with 6 files : YAML speed is 2 of custom
      (1..2).each do |i|
        @b.changesets.add(RSCM::Change.new("myfile1", "aslak", "hello", "99", Time.utc(1970 + i)))
        @b.changesets.add(RSCM::Change.new("myfile2", "aslak", "hello", "99", Time.utc(1970 + i)))
        @b.changesets.add(RSCM::Change.new("myfile3", "aslak", "hello", "97", Time.utc(1970 + i)))
        @b.changesets.add(RSCM::Change.new("myfile13", "aslak", "hello", "99", Time.utc(1970 + i)))
        @b.changesets.add(RSCM::Change.new("myfile23", "aslak", "hello", "99", Time.utc(1970 + i)))
        @b.changesets.add(RSCM::Change.new("myfile33", "aslak", "hello", "97", Time.utc(1970 + i)))
      end
    end

    def test_writes_many_small_files_when_serializing_build
      
      build_dir = new_temp_dir
      bs = BuildSerializer.new
      
      bs.dump(@b, build_dir)

      assert(File.exist?("#{build_dir}/dc_start_time=19710228234507"))
      assert(File.exist?("#{build_dir}/scm_commit_time=19710228234502"))
      assert(File.exist?("#{build_dir}/duration=123"))
      assert(File.exist?("#{build_dir}/status=BUILDING"))
      assert(@b.changesets == YAML::load(File.new("#{build_dir}/changesets.yaml")))
      
      # Modify some props and write again
      @b.duration = 246
      @b.status = Build::SUCCESSFUL
      bs.dump(@b, build_dir)

      assert(!File.exist?("#{build_dir}/duration=123"))
      assert(!File.exist?("#{build_dir}/status=BUILDING"))
      assert(File.exist?("#{build_dir}/duration=246"))
      assert(File.exist?("#{build_dir}/status=SUCCESSFUL"))
    end
    
    def test_can_deserialize_serialized_build
      temp_dir = new_temp_dir
      build_dir = "#{temp_dir}/jalla/build/19710228234501"
      bs = BuildSerializer.new
      bs.dump(@b, build_dir)
      assert_equal(@b, bs.load(build_dir, true))
    end
    
    def test_deserialization_speed
      n = 100
      temp_dir = new_temp_dir
      build_dir = "#{temp_dir}/jalla/build/19710228234501"

      bs = BuildSerializer.new
      bs.dump(@b, build_dir)
      custom_ser_start = Time.new.utc
      (1..n).each do
        bs.load(build_dir, false)
      end
      custom_ser_dur = (Time.new.utc - custom_ser_start) / n

      yaml = "#{build_dir}/build.yaml"
      File.open(yaml, "w") do |io|
        YAML::dump(@b, io)
      end
      yaml_ser_start = Time.new.utc
      (1..n).each do
        YAML::load(File.open(yaml).read)
      end
      yaml_ser_dur = (Time.new.utc - yaml_ser_start) / n
      
      puts "custom serialisation is #{yaml_ser_dur / custom_ser_dur} times faster than yaml"
    end

  end
end
