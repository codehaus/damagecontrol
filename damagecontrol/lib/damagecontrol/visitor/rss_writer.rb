module DamageControl
  module Visitor
    # Visitor that writes RSS for ChangeSets.
    class RssWriter

      # Creates a new RssWriter that will populate the +rss+
      # object when it is accepted by a ChangeSets object.
      def initialize(rss, title, link, description, message_linker, change_linker)
        raise "title" unless title
        raise "link" unless link
        raise "description" unless description
        raise "message_linker" unless message_linker
        raise "change_linker" unless change_linker

        @rss, @title, @link, @description, @message_linker, @change_linker = rss, title, link, description, message_linker, change_linker
      end

      def visit_changesets(changesets)
        @rss.channel.title = @title
        @rss.channel.link = @link
        @rss.channel.description = @description
        @rss.channel.generator = "DamageControl"
      end

      def visit_changeset(changeset)
        @item = @rss.items.new_item

        @item.pubDate = changeset.time
        @item.author = changeset.developer
        @item.title = changeset.message
        @item.link = @change_linker.changeset_url(changeset, true)

        @item.description = "<b>#{changeset.developer}</b><br/>\n"
        @item.description << @message_linker.highlight(changeset.message).gsub(/\n/, "<br/>\n") << "<p/>\n"
      end

      def visit_change(change)
        @item.description << @change_linker.change_url(change, true) << "<br/>\n"
      end

    end
  end
end
