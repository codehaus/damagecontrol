require File.dirname(__FILE__) + '/../../test_helper'

module DamageControl  
  class ZipperTest < Test::Unit::TestCase
    def test_should_zip_working_copy_and_yield_zip_for_extra_contents
      zipfile_name = File.dirname(__FILE__) + '/../../../target/ziptest.zip'
      File.delete zipfile if File.exist?(zipfile_name)
      FileUtils.mkdir_p(File.dirname(zipfile_name))

      dir = File.dirname(__FILE__) + '/../../..'
      zipper = Zipper.new
      zipper.zip(dir, zipfile_name, ["target/*", "projects/*", "artifacts/*"]) do |zipfile|
        zipfile.file.open("damagecontrol_build_info.yml", "w") do |f| 
          f.write({:build_command => "rake", :environment=>{"PKG_BUILD" => 8888}}.to_yaml)
        end
      end
      
      Zip::ZipFile.open(zipfile_name) do |zipfile|
        damagecontrol_build_info = YAML.load(zipfile.file.read("damagecontrol_build_info.yml"))
        assert_equal(8888, damagecontrol_build_info[:environment]["PKG_BUILD"]);
      end
    end
  end
end