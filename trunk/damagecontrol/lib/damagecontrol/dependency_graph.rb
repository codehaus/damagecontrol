require 'rubygems'
require 'rgl/adjacency'
require 'rgl/dot'

module DamageControl
  # Helper class that writes a dependency graph of objects to a graphichs file
  class DependencyGraph
    def initialize(projects)
      @projects = projects
    end
    
    def write_to(file)
      dag = RGL::DirectedAdjacencyGraph.new
      @projects.each do |project|
        project.dependencies.each do |dep|
          dag.add_edge(project.name, dep.name)
        end
        dag.add_vertex(project.name)
      end

      ext = File.extname(file)[1..-1]
      base = file[0..-ext.length-2]

      dag.write_to_graphic_file(ext, base)
    end
  end
end