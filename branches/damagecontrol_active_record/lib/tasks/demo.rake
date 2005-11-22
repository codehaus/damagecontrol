require 'rscm'

cvsroot = "target/demo/cvsroot"
path = RSCM::PathConverter.filepath_to_nativepath(cvsroot, true)
cvs = RSCM::Cvs.new(":local:#{path}", "demo")

desc "Creates a demo project in DamageControl"
task :create_demo_project => [:migrate, :create_demo_cvs, :import_demo] do
  p = Project.find_by_name("demo")
  p.destroy if p

  cvs.uses_polling = true
  Project.create(
    :name => "demo",
    :build_command => "rake",
    :scm => cvs,
    :publishers => [],
    :tracker => nil
  )

  puts "Check out a working copy to your hard disk with"
  puts
  puts "  mkdir tmp"
  puts "  cd tmp"
  puts "  cvs -d#{cvs.root} checkout #{cvs.mod}"
  puts "  cd demo"
  puts
  puts "Edit the Rakefile in your working copy and check it in:"
  puts 
  puts "  cvs commit -m \"changed something\""
  puts 
  puts "Observe DamageControl building your changes"
end

task :create_demo_cvs do
  mkdir_p cvsroot unless File.exist? cvsroot
  if(cvs.central_exists?)
    cvs.destroy_central
  end
  cvs.create_central
end

desc "Copy the demo sources to get rid of .svn files before we import to CVS"
task :copy_demo
import_dir = "target/demo/import"
FileList.new("demo/**/*").each do |src|
  directory import_dir
  target = File.join import_dir, "demo", File.basename(src)
  file target => [src, import_dir] do
    if(File.directory?(src))
      mkdir_p target unless File.exist?(target)
    else
      mkdir_p File.dirname(target) unless File.exist?(File.dirname(target))
      cp src, target
    end
  end
  task :copy_demo => target
end

task :import_demo => :copy_demo do
  cvs.import_central("#{import_dir}/demo", "import sources")
end
