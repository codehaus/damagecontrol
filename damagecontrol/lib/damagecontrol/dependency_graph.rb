require 'rubygems'
require 'rgl/adjacency'
require 'rgl/dot'

module DamageControl
  class ProjectGraph < RGL::DirectedAdjacencyGraph
    def to_dot_graph
      graph = DOT::DOTDigraph.new({'name' => ""})

      fontsize   = '8'
      each_vertex do |v|
        graph << DOT::DOTNode.new(
          'name'    => v.to_s,
          'url'     => "ajax/#{v.to_s}"
        )
      end
      each_edge do |u,v|
        graph << DOT::DOTDirectedEdge.new(
          'from'     => u.to_s,
          'to'       => v.to_s
        )
      end
      graph
    end
  end

  # Helper class that writes a dependency graph of objects to a graphichs file
  class DependencyGraph
    def initialize(projects)
      @projects = projects
    end

    def write_to(file)
      dag = ProjectGraph.new
      @projects.each do |project|
        project.dependencies.each do |dep|
          dag.add_edge(project.name, dep.name)
        end
        dag.add_vertex(project.name)
      end

      ext = File.extname(file)[1..-1]
      base = file[0..-ext.length-2]

      dag.write_to_graphic_file("cmap", base)
      dag.write_to_graphic_file(ext, base)
      
      # Write the full HTML
      File.open("#{base}.html", 'w') do |io|
        io.puts("<img src=\"/project_dependencies/image\" usemap=\"#project_dependencies\">")
        io.puts("<map name=\"project_dependencies\">")
        io.puts(File.open("#{base}.cmap").read)
        io.puts("</map>")
      end
    end
  end
end

# Patches to RGL's DOT classes
module DOT
  class DOTDigraph
    def initialize(params = {}, option_list = GRAPH_OPTS)   
      super(params, option_list)
      @dot_string = 'digraph G'
    end
  end

  class DOTNode
    def initialize(params)
      @params = params
      @name = @params.delete('name')
    end

    def to_s(huh=nil)
      "    \"#{name}\" [\n" +
      "        URL = \"#{@params['url']}\"\n" +
      "    ]\n"
    end
  end

  class DOTDirectedEdge
    def to_s(huh=nil)
      "    \"#{@from}\" -> \"#{to}\""
    end
  end
end
