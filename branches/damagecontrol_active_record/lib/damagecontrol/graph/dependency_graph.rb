module DamageControl
  # This class knows how to generate a GraphViz DOT image map for the project
  # dependencies
  class DependencyGraph
    def initialize(current_project, projects, dummy_class, with_map=true)
      @current_project = current_project
      @projects = projects
      @dummy_class = dummy_class
      @with_map = with_map
    end

    def write_to(file)
      legal_dependencies = []
      g = ProjectGraph.new(@current_project.name, legal_dependencies)
      @projects.each do |project|
        if(!project.depends_on?(@current_project) && project.name != @current_project.name)
          legal_dependencies << project.name
        end

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
        if(@with_map)
          io.puts("<img src=\"/dependency/image?dummy=#{@dummy_class.new.to_s}\" usemap=\"#project_dependencies\">")
        else
          io.puts("<img src=\"/dependency/image?dummy=#{@dummy_class.new.to_s}\">")
        end
        io.puts("<map name=\"project_dependencies\">")
        # replace anchor attributes in the dot-generated map so they are fired by onclick (ajax)
        io.puts(File.open("#{base}.cmap").read.gsub(/href=/, "href=\"#\" onclick="))
        io.puts("</map>")
      end
    end
  end

  # RGL Graph that knows how to add RoR Ajax-aware URL attributes to each nodes
  class ProjectGraph < RGL::DirectedAdjacencyGraph
  
    def initialize(current_project_name, legal_dependencies)
      super(Set)
      @current_project_name = current_project_name
      @legal_dependencies = legal_dependencies
    end
  
    def to_dot_graph
      graph = DOT::DOTDigraph.new({'name' => ""})
      fontsize   = '8'
      each_vertex do |project_name|
        operation = has_edge?(@current_project_name, project_name) ? "remove" : "add"
        fillcolor = (@current_project_name == project_name) ? "yellow" : "white"
        params = {
          'name'      => project_name,
          'fillcolor' => fillcolor,
        }
        if(@legal_dependencies.index(project_name))
          # This URL scheme is defined in config/routes.rb
          params['url'] = "javascript:new Ajax.Updater('dependency_graph', '/projects/#{@current_project_name}/#{operation}_dependency/#{project_name}', {asynchronous:true});"
        end
        graph << DOT::DOTNode.new(params)
      end
      each_edge do |n1,n2|
        graph << DOT::DOTDirectedEdge.new(
          'from'     => n1,
          'to'       => n2
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
      "    \"#{@name}\" [\n" +
      (@params['url'] ? "        URL = \"#{@params['url']}\"\n" : "") +
      "        style = filled\n" +
      "        fillcolor = #{@params['fillcolor']}\n" +
      "    ]\n"
    end
  end

  class DOTDirectedEdge
    def to_s(huh=nil)
      "    \"#{@from}\" -> \"#{to}\""
    end
  end
end
