require 'damagecontrol/tool/Task'

module DamageControl
class ChangesetsTask < ConfigTask
  commandline_option :projectname
  commandline_option :buildnumber1
  commandline_option :buildnumber2
  
  def build(build_number)
    server.build_history_repository.build_with_number(projectname, build_number)
  end
  
  def run
    build1 = build(buildnumber1)
    build2 = build(buildnumber2)
    scm = server.project_config_repository.create_scm(projectname)
    changesets = scm.changesets(build1.timestamp_as_time, build2.timestamp_as_time)
    changesets.each do |changeset|
      puts "#{changeset.developer} : #{changeset.message}"
      changeset.each do |change|
        puts "#{change.status}\t#{change.revision}\t#{change.path}"
      end
    end
  end
end
end

DamageControl::ChangesetsTask.new.run