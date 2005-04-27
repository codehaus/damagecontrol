require 'damagecontrol/dependency_graph'

class DependencyController < ApplicationController
  IMAGE_MAP_HTML = "#{BASEDIR}/projects/dependency_graph.html"
  IMAGE          = "#{BASEDIR}/projects/dependency_graph.png"

  # Renders a dependency graph of all projects
  def image_map_html
    from_name = @params["id"]
    from = DamageControl::Project.load("#{BASEDIR}/projects/#{from_name}/project.yaml")
    projects = DamageControl::Project.find_all("#{BASEDIR}/projects")
    dg = DamageControl::DependencyGraph.new(from, projects)
    dg.write_to(IMAGE)
    send_file(IMAGE_MAP_HTML)
  end  

  def image
    send_file(IMAGE)
  end
  
  def add_dependency
    from_name = @params["id"]
    from = DamageControl::Project.load("#{BASEDIR}/projects/#{from_name}/project.yaml")
    to_name = @params["to"]
    to   = DamageControl::Project.load("#{BASEDIR}/projects/#{to_name}/project.yaml")
    from.add_dependency(to)
    from.save
    image_map_html
  end
  
  def remove_dependency
    from_name = @params["id"]
    from = DamageControl::Project.load("#{BASEDIR}/projects/#{from_name}/project.yaml")
    to_name = @params["to"]
    to   = DamageControl::Project.load("#{BASEDIR}/projects/#{to_name}/project.yaml")
    from.remove_dependency(to)
    from.save
    image_map_html
  end
  
end