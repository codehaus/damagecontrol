require 'rubygems'
require 'rgl/adjacency'
require 'rgl/topsort'
require 'rgl/connected_components'

require 'test/unit'
require 'rgl/dot'

=begin
(This is how I'd like things to work - they don't yet - AH)
Spike of DC-331, DC-151, DC-231 and some other issue i don't remember

- Dependent builds

It is very common that independent software projects have interdependencies. This applies to all sorts
of projects, whether they are commercial, open source or other.

It is also quite common that projects under development have dependencies on other projects that are
also under development *(examples). In many cases it makes sense to take advantage of floating dependencies *(definition),
since this can simplify the burden of integration and favour greater feedback between projects.

The build of a project that has floating dependencies on other projects may break if any of its dependent projects break.
DamageControl can support multiple projects with floating dependencies by automatically triggering builds of dependent projects.

- Queues and dependent builds

DC also supports dependencies in queues. Imagine that DC has 3 projects with the following dependencies, and one single
build executor:

  A   B->C

A is put on the build queue and B is put on the build queue right after. DC will start to build A, and B is scheduled
to be built when A is done. However, someone requests the build of C before A is complete. DC will use its knowledge of
the project dependencies and put C on the build queue before B!

When A is done, C will be built, which will trigger the build of C when it's done (because B depends on C). This is much
more efficient than the linear sequence A, B, C, B, since we avoid building B twice. In very active developer environments
this can cause significant optimisation and avoid a lot of redundant builds.

=end

module DamageControl

  class Project
    attr_reader :name
  
    def initialize(name)
      @name = name
      @dependencies = []
    end
    
    def add_dependency(project)
      @dependencies << project.name
    end
    
    def update(graph)
      @dependencies.each{|project_name| graph.add_edge(name, project_name)}
    end
    
    def build_seq(graph)
      rev = graph.reverse
      top = rev.topsort_iterator.to_a
      vertices = [name]
      recurse(rev, vertices, name)
      top - (top-vertices)
    end

    def recurse(graph, vertices, vertex)
      graph.each_adjacent(vertex) do |adj|
        vertices << adj unless vertices.index(adj)
        recurse(graph, vertices, adj)
      end
    end
    
  end

  class ProjectDependenciesTest < Test::Unit::TestCase

    #
    #             kid
    #           /     \
    #          V       V
    #       fred      boo
    #       /    \    /
    #      V      V  V
    #   wilma    barney
    #              |
    #              V
    #            dino
    #
    #  yyy  : yyy depends on xxx
    #   |
    #   V
    #  xxx  : build of xxx trigs build of yyy
    #
    def test_should_build_dependent_projects
      boo = Project.new("boo")
      fred = Project.new("fred")
      wilma = Project.new("wilma")
      barney = Project.new("barney")
      dino = Project.new("dino")
      kid = Project.new("kid")

      fred.add_dependency(wilma)
      fred.add_dependency(barney)
      barney.add_dependency(dino)
      boo.add_dependency(barney)
      kid.add_dependency(fred)
      kid.add_dependency(boo)
      
      graph = RGL::DirectedAdjacencyGraph.new
      fred.update(graph)
      wilma.update(graph)
      barney.update(graph)
      dino.update(graph)
      boo.update(graph)
      kid.update(graph)
      
#      graph.write_to_graphic_file("png", "flintstones_deps")
      
      assert_equal(["dino", "barney", "fred", "boo", "kid"], dino.build_seq(graph))
    end

  end

end
