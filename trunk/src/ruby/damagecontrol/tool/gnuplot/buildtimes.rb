$damagecontrol_home = File::expand_path('../../../../..') 
$:<<"#{$damagecontrol_home}/src/ruby" 
$:<<"#{$damagecontrol_home}/lib" 

require 'damagecontrol/Build'
require 'damagecontrol/AsyncComponent'
require 'damagecontrol/BuildHistoryRepository'
require 'yaml'

project_name = "damagecontrol"

repo = DamageControl::BuildHistoryRepository.new(nil, "build_history_sample.yaml")
pico = repo.get_build_list_map(project_name)[project_name]
i = 0
data = File.new("#{project_name}.dat", "w")
pico.each do |build|
  if(build.status == DamageControl::Build::SUCCESSFUL && !build.end_time.nil? && !build.start_time.nil?)
    data.puts i.to_s + " " + (build.end_time - build.start_time).to_s
    i += 1
  end
end
data.close

script = File.new("#{project_name}.gnuplot", "w")
script_content = <<-EOF
set term png small
set style data lines
set grid
set title "#{project_name} build durations"
set xlabel "Build date"
set ylabel "Build duration"
plot "#{project_name}.dat"
EOF
script.puts(script_content)
script.close

IO.popen("gnuplot #{project_name}.gnuplot > #{project_name}.png")