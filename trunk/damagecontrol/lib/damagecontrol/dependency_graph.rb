require 'rubygems'
require 'rgl/adjacency'
require 'rgl/dot'

module DamageControl
  # This class knows how to generate a GraphViz DOT image map for the project
  # dependencies
  class DependencyGraph
    def initialize(project, projects, dummy_class=Time)
      @project = project
      @projects = projects
      @dummy_class = dummy_class
    end

    def write_to(file)
      g = ProjectGraph.new(@project)
      @projects.each do |project|
        project.dependencies.each do |dep|
          g.add_edge(project.name, dep.name)
        end
        g.add_vertex(project.name)
      end

      ext = File.extname(file)[1..-1]
      base = file[0..-ext.length-2]

      g.write_to_graphic_file("cmap", base)
      g.write_to_graphic_file(ext, base)
      
      # Write the full HTML
      File.open("#{base}.html", 'w') do |io|
        # The dummy is to fool the browser to re-request the image.
        io.puts("<img src=\"/dependency/image?dummy=#{@dummy_class.new.to_s}\" usemap=\"#project_dependencies\">")
        io.puts("<map name=\"project_dependencies\">")
        io.puts(File.open("#{base}.cmap").read.gsub(/href=/, "href=\"#\" onclick="))
        io.puts("</map>")
      end
    end
  end

  # RGL Graph that knows how to add RoR Ajax-aware URL attributes to each nodes
  class ProjectGraph < RGL::DirectedAdjacencyGraph
  
    def initialize(current_project)
      super(Set)
      @current_project = current_project
    end
  
    def to_dot_graph
      graph = DOT::DOTDigraph.new({'name' => ""})

      fontsize   = '8'
      each_vertex do |v|
        operation = has_edge?(@current_project, v) ? "remove" : "add"
        graph << DOT::DOTNode.new(
          'name'    => v.to_s,
          # This URL scheme is defined in config/routes.rb
          'url'     => "javascript:new Ajax.Updater('dependency_graph', '/projects/DamageControl/#{operation}_dependency/#{v.to_s}', {asynchronous:true});"
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
