require 'rss/maker'

module RSCM

  class ChangeSets
    include Enumerable

    attr_reader :changesets

    def initialize(changesets=[])
      @changesets = changesets
    end

    def [](change)
      @changesets[change]
    end

    # Iterates over changesets in reverse order of creation
    # This is because we want to have the most recent at the top
    def each(&block)
      # Umm - seems to go into infinite loop!?!?!
      # @changesets.reverse.each(&block)
      @changesets.each(&block)
    end
    
    def length
      @changesets.length
    end

    def ==(other)
      return false if !other.is_a?(self.class)
      @changesets == other.changesets
    end
    
    def empty?
      @changesets.empty?
    end

    # Adds a Change or a ChangeSet.
    # If the argument is a Change and no corresponding ChangeSet exists,
    # a new ChangeSet is created, added, and the Change is added to that ChangeSet -
    # and then finally the newly created ChangeSet is returned.
    # Otherwise nil is returned.
    def add(change_or_changeset)
      if(change_or_changeset.is_a?(ChangeSet))
        @changesets << change_or_changeset
        return change_or_changeset
      else
        changeset = @changesets.find { |a_changeset| a_changeset.can_contain?(change_or_changeset) }
        if(changeset.nil?)
          changeset = ChangeSet.new
          @changesets << changeset
          changeset << change_or_changeset
          return changeset
        end
        changeset << change_or_changeset
        return nil
      end
    end
    
    def push(*change_or_changesets)
      change_or_changesets.each { |change_or_changeset| self << (change_or_changeset) }
      self
    end

    # The most recent time of all the ChangeSet s.
    def time
      time = nil
      changesets.each do |changeset|
        time = changeset.time if @time.nil? || @time < changeset.time
      end
      time
    end

    def to_rss(title, link, description, message_linker, change_linker)
      RSS::Maker.make("2.0") do |rss|
        rss.channel.title = title
        rss.channel.link = link
        rss.channel.description = description

        changesets.each do |changeset|
          item = rss.items.new_item
          
          item.pubDate = changeset.time
          item.title = changeset.message
          item.link = change_linker.changeset_url(changeset, true)
          item.description = message_linker.highlight(changeset.message).gsub(/\n/, "<br/>\n") << "<p/>\n"
          changeset.each do |change|
            item.description << change_linker.change_url(change, true) << "<br/>\n"
          end
        end
        rss.to_rss
      end
    end

  end

  class ChangeSet
    include Enumerable

    attr_reader :changes
    attr_accessor :revision
    attr_accessor :developer
    attr_accessor :message
    attr_accessor :time

    def initialize(changes=[])
      @changes = changes
    end
    
    def << (change)
      @changes << change
      self.time = change.time if self.time.nil? || self.time < change.time unless change.time.nil?
      self.developer = change.developer if change.developer
      self.message = change.message if change.message
    end

    def [] (change)
      @changes[change]
    end

    def each(&block)
      @changes.each(&block)
    end
    
    def length
      @changes.length
    end

    def time=(t)
      raise "time must be a Time object" unless t.is_a?(Time)
      raise "can't set time to an inferiour value than the previous value" if @time && (t < @time)
      @time = t
    end
    
    def ==(other)
      return false if !other.is_a?(self.class)
      @changes == other.changes
    end

    def can_contain?(change)
      self.developer == change.developer &&
      self.message == change.message &&
      (self.time - change.time).abs < 60
    end

    def format(template, format_time=Time.new.utc)
      time_difference = time_difference(format_time)
      ERB.new(template).result(binding)
    end
    
    def time_difference(format_time=Time.new.utc)
      return "UNKNOWN" unless time
      time_difference = format_time.difference_as_text(time)
    end
    
    def to_s
      result = "#{revision} | #{developer} | #{time} | #{message}\n"
      self.each do |change|
        result << " " << change.to_s << "\n"
      end
      result
    end
  end

  class Change

    MODIFIED = "MODIFIED"
    DELETED = "DELETED"
    ADDED = "ADDED"
    MOVED = "MOVED"
    
    attr_accessor :status
    attr_accessor :path
    attr_accessor :previous_revision
    attr_accessor :revision

    # TODO: Remove redundant attributes that are in ChangeSet
    attr_accessor :developer
    attr_accessor :message
    # This is a UTC ruby time
    attr_accessor :time
    
    def initialize(path=nil, developer=nil, message=nil, revision=nil, time=nil)
      @path, @developer, @message, @revision, @time = path, developer, message, revision, time
    end
  
    def to_s
      "#{path} | #{revision}"
    end

    def to_rss_description
      status_text = status.nil? ? path : "#{status.capitalize} #{path}"
    end
  
    def developer=(developer)
      raise "can't be null" if developer.nil?
      @developer = developer
    end
    
    def message=(message)
      raise "can't be null" if message.nil?
      @message = message
    end

    def path=(path)
      raise "can't be null" if path.nil?
      @path = path
    end

    def revision=(revision)
      raise "can't be null" if revision.nil?
      @revision = revision
    end

    def time=(time)
      raise "time must be a Time object" unless time.is_a?(Time)
      @time = time
    end

    def ==(other)
      return false if !other.is_a?(self.class)
      self.path == other.path &&
      self.developer == other.developer &&
      self.message == other.message &&
      self.revision == other.revision &&
      self.time == other.time
    end

  end

end
