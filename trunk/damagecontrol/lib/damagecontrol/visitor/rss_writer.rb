module DamageControl
  module Visitor
    # Visitor that writes RSS for Revisions.
    class RssWriter

      # Creates a new RssWriter that will populate the +rss+
      # object when it is accepted by a Revisions object.
      def initialize(rss, title, link, description, message_linker, change_linker)
        raise "title" unless title
        raise "link" unless link
        raise "description" unless description
        raise "message_linker" unless message_linker
        raise "change_linker" unless change_linker

        @rss, @title, @link, @description, @message_linker, @change_linker = rss, title, link, description, message_linker, change_linker
      end

      def visit_revisions(revisions)
        @rss.channel.title = @title
        @rss.channel.link = @link
        @rss.channel.description = @description
        @rss.channel.generator = "DamageControl"
      end

      def visit_revision(revision)
        @item = @rss.items.new_item

        @item.pubDate = revision.time
        @item.author = revision.developer
        @item.title = revision.message
        @item.link = @change_linker.revision_url(revision, true)

        @item.description = "<b>#{revision.developer}</b><br/>\n"
        @item.description << @message_linker.highlight(revision.message).gsub(/\n/, "<br/>\n") << "<p/>\n"
      end

      def visit_file(change)
        @item.description << @change_linker.file_url(change, true) << "<br/>\n"
      end

    end
  end
end
