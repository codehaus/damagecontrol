require 'damagecontrol/dependency_graph'

class DependencyController < ApplicationController
  # Renders a dependency graph of all projects
  def graph
    dg = DamageControl::DependencyGraph.new(DamageControl::Project.find_all("#{BASEDIR}/projects"))
    img = "#{BASEDIR}/projects/dependency_graph.png"
    dg.write_to(img)
    send_file(img)
  end  
end