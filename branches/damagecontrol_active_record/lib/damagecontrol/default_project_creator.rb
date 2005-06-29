# Creates default projects
if(!Project.find_by_name("DamageControl"))
  puts "Creating project DamageControl"
  damagecontrol = Project.create(
    :name => "DamageControl",
    :home_page => "http://hieraki.lavalamp.ca/",
    :start_time => Time.utc(2004, 1, 1, 0, 0, 0, 0), 
    :relative_build_path => "", 
    :build_command => "rake", 
    :scm => RSCM::Subversion.new("svn://beaver.codehaus.org/damagecontrol/scm/trunk")
  )
end