require 'test/unit'
require 'rscm/threadfile'

class ThreadFileTest < Test::Unit::TestCase
  def test_should_keep_pwd_per_thread

    dirs = ["app", "config", "ext"].collect{|dir| File.expand_path(dir)}
    subdirs = ["controllers", "environments", "java"]
    subdir_files = ["scm_controller.rb", "production.rb", "build.xml"]
    
    subdir_entries = []
    dirs.each_index do |i|
      dir = dirs[i]
      subdir = subdirs[i]
      subdir_entries[i] = Dir.entries("#{dir}/#{subdir}")
      
#      puts "#{dir}/#{subdir} **> " + subdir_entries[i].join(",")
    end
    
    t = []
    dirs.each_index do |i|
      dir = dirs[i]
      subdir = subdirs[i]
      subdir_file = subdir_files[i]
      t << Thread.new do
        Dir.chdir(dir)
        sleep 1
        expected = "#{dir}/#{subdir}"
        assert_equal(expected, File.expand_path(subdir))
        assert(File.exist?(expected))
        assert(File.directory?(expected))
#        puts expected + " --> " + Dir.entries(subdir).join(",")
        Dir.chdir(subdir)
        File.open(subdir_file) do |io|
          io.read
        end
      end
    end

    t.each{|t| t.join}
  end
end
