require 'test/unit'
require 'rubygems'
require_gem 'rscm'
require 'pebbles/mockit'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/ArtifactArchiver'
require 'damagecontrol/scm/NoSCM'

module DamageControl  
  class ArtifactArchiverTest < Test::Unit::TestCase
    include FileUtils
    include MockIt
    
    def test_copies_away_artifacts_on_build_complete
      basedir = new_temp_dir
      
      build = Build.new("project", {
        "artifacts_to_archive" => [ "target/*.jar", "target/jars" ]
      })
      
      mkdir_p("#{basedir}/checkout/target/jars")
      touch("#{basedir}/checkout/target/1.jar")
      touch("#{basedir}/checkout/target/1.zip")
      touch("#{basedir}/checkout/target/jars")
      touch("#{basedir}/checkout/target/jars/2.jar")
      touch("#{basedir}/checkout/target/jars/3.jar")
      
      hub = new_mock
      hub.__expect(:add_consumer) do |subscriber|
        assert(subscriber.is_a?(ArtifactArchiver))
      end

      archive_dir = "#{basedir}/archive"
      project_directories = new_mock
      project_directories.__expect(:checkout_dir) { "#{basedir}/checkout" }
      project_directories.__expect(:archive_dir) { archive_dir }
      aa = ArtifactArchiver.new(
        hub,
        project_directories
      )
      aa.put(BuildCompleteEvent.new(build))
      
      assert_equal(["#{archive_dir}/1.jar", "#{archive_dir}/jars"], Dir["#{archive_dir}/*"].sort)
      assert_equal(["#{archive_dir}/jars/2.jar", "#{archive_dir}/jars/3.jar"], Dir["#{archive_dir}/jars/*"].sort)
    end
  end
end