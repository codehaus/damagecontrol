require 'test/unit'
require 'pebbles/mockit'

require 'damagecontrol/core/Build'
require 'damagecontrol/core/ArtifactArchiver'
require 'damagecontrol/scm/NoSCM'

module DamageControl  
  class ArtifactArchiverTest < Test::Unit::TestCase
    include FileUtils
    
    def test_copies_away_artifacts_on_build_complete
      basedir = new_temp_dir
      
      build_timestamp = "19770615120000"
      build = Build.new("project", build_timestamp, {
        "artifacts_to_archive" => [ "target/*.jar", "target/jars" ]
      })
      
      build.archive_dir = "#{basedir}/project/archive/#{build_timestamp}"
      build.scm = NoSCM.new
      build.scm.checkout_dir = "#{basedir}/checkout"
      
      mkdir_p("#{basedir}/checkout/target/jars")
      touch("#{basedir}/checkout/target/1.jar")
      touch("#{basedir}/checkout/target/jars")
      touch("#{basedir}/checkout/target/jars/2.jar")
      touch("#{basedir}/checkout/target/jars/3.jar")
      
      hub = MockIt::Mock.new
      hub.__expect(:add_subscriber) do |subscriber|
        assert(subscriber.is_a?(ArtifactArchiver))
      end

      aa = ArtifactArchiver.new(hub)
      aa.put(BuildCompleteEvent.new(build))
      
      assert_equal(["#{build.archive_dir}/1.jar", "#{build.archive_dir}/jars"], Dir["#{build.archive_dir}/*"].sort)
      assert_equal(["#{build.archive_dir}/jars/2.jar", "#{build.archive_dir}/jars/3.jar"], Dir["#{build.archive_dir}/jars/*"].sort)
    end
  end
end