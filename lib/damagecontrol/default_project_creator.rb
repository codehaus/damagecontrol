# Creates default projects
if(!Project.find_by_name("DamageControl (damagecontrol_active_record branch)"))
  damagecontrol = Project.create(
    :name => "DamageControl (damagecontrol_active_record branch)",
    :home_page => "http://hieraki.lavalamp.ca/",
    :start_time => 2.weeks.ago.utc, 
    :relative_build_path => "", 
    :build_command => "rake", 
    :scm => RSCM::Subversion.new("svn://beaver.codehaus.org/damagecontrol/scm/branches/damagecontrol_active_record")
  )
end

if(!Project.find_by_name("DamageControl (trunk)"))
  damagecontrol = Project.create(
    :name => "DamageControl (trunk)",
    :home_page => "http://hieraki.lavalamp.ca/",
    :start_time => 2.weeks.ago.utc, 
    :relative_build_path => "", 
    :build_command => "rake", 
    :scm => RSCM::Subversion.new("svn://beaver.codehaus.org/damagecontrol/scm/trunk/damagecontrol")
  )
end

if(!Project.find_by_name("RSCM (trunk)"))
  damagecontrol = Project.create(
    :name => "RSCM (trunk)",
    :home_page => "http://rscm.rubyforge.org/",
    :start_time => 2.weeks.ago.utc, 
    :relative_build_path => "", 
    :build_command => "rake", 
    :scm => RSCM::Subversion.new("svn://beaver.codehaus.org/damagecontrol/scm/trunk/rscm")
  )
end

if(!Project.find_by_name("Ruby (trunk)"))
  damagecontrol = Project.create(
    :name => "Ruby (trunk)",
    :home_page => "http://ruby-lang.org/",
    :start_time => 2.weeks.ago.utc, 
    :relative_build_path => "", 
    :build_command => "autoconf;./configure;make", 
    :scm => RSCM::Cvs.new(":pserver:anonymous@cvs.ruby-lang.org:/src", "ruby")
  )
end

