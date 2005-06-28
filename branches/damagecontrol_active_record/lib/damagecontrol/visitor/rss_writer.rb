module DamageControl
  module Visitor
    # Visitor that writes RSS for Revisions.
    class RssWriter

      # Creates a new RssWriter that will populate the +rss+
      # object when it is accepted by a Revisions object.
      def initialize(rss, project, controller, commit_message_linker)
        raise "project" unless project
        raise "controller" unless controller
        raise "commit_message_linker" unless commit_message_linker

        @rss, @project, @controller, @commit_message_linker = rss, project, controller, commit_message_linker
      end

      def visit_revisions(revisions)
        @rss.channel.title = "#{@project.name} revisions"
        @rss.channel.link = @controller.url_for(:controller => "project", :action => "view", :id => @project.name)
        @rss.channel.description = "#{@project.name} revisions"
        @rss.channel.generator = "DamageControl"
      end

      def visit_revision(revision)
        @item = @rss.items.new_item

        @item.pubDate = revision.time
        @item.author = revision.developer
        @item.title = "#{revision.identifier}: #{revision.message}"
        @item.link = @controller.url_for(:controller => "project", :action => "revision", :id => @project.name, :params => {"revision" => revision.identifier})

        @item.description = "<b>#{revision.developer}</b><br/>\n"
        @item.description << @commit_message_linker.highlight(revision.message).gsub(/\n/, "<br/>\n") << "<p/>\n"
        @file_index = 0
      end

      def visit_file(file)
        url = @controller.url_for(:controller => "scm", :action => "diff_with_previous", :id => @project.name, :params => {"revision_identifier" => file.revision.identifier, "file_index" => @file_index})
        @item.description << "<a href=\"#{url}\">#{file.path}</a><br/>\n"
        @file_index += 1
      end

    end
  end
end
