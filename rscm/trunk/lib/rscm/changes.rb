require 'rss/maker'
require 'xmlrpc/utils'
require 'rscm/directories'
require 'rscm/time_ext'

module RSCM

  class ChangeSets
    include Enumerable
    include XMLRPC::Marshallable

    attr_reader :changesets

    def initialize(changesets=[])
      @changesets = changesets
    end

    def [](change)
      @changesets[change]
    end

    def each(&block)
      @changesets.each(&block)
    end
    
    def reverse
      ChangeSets.new(@changesets.reverse)
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
    
    def developers
      result = []
      each do |changeset|
        result << changeset.developer unless result.index(changeset.developer)
      end
      result
    end
    
    # The latest ChangeSet (with the latest time)
    # or nil if this changeset is empty
    def latest
      latest = nil
      each do |changeset|
        latest = changeset if latest.nil? || latest.time < changeset.time
      end
      latest
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

    # Writes RSS for the changesets to file.
    def write_rss(title, rss_file, link, description, message_linker, change_linker)
      FileUtils.mkdir_p(File.dirname(rss_file))
      File.open(rss_file, "w") do |io|
        rss = to_rss(
          title, 
          link,
          description, 
          message_linker, 
          change_linker
        )
        io.write(rss)
      end
    end

    # Writes the changesets to several YAML files.
    def save(changesets_dir)
      self.each do |changeset|
        changeset.save(changesets_dir)
      end
    end

    # Loads +prior+ number of changesets upto +last_changeset_id+ 
    # from the +changesets+ dir. +last_changeset_id+ should be the 
    # dirname of the folder containing the last changeset.
    def ChangeSets.load_upto(changesets_dir, last_changeset_id, prior)
      last_changeset_id = last_changeset_id.to_i
      ids = ChangeSets.ids(changesets_dir)
      last = ids.index(last_changeset_id)
      raise "No occurrence of #{last_changeset_id.inspect} in #{ids.inspect}" unless last
      first = last - prior + 1
      first = 0 if first < 0

      changesets = ChangeSets.new
      ids[first..last].each do |id|
        changesets.add(YAML::load_file("#{changesets_dir}/#{id}/changesets.yaml"))
      end
      changesets
    end

    # Returns a sorted array of ints representing the changeset directories.
    def ChangeSets.ids(changesets_dir)
      dirs = Dir["#{changesets_dir}/*"].find_all {|f| File.directory?(f) && File.exist?("#{f}/changesets.yaml")}
      # Turn them into ints so they can be sorted.
      dirs.collect { |dir| File.basename(dir).to_i }.sort
    end

    # Returns the id of the latest changeset.
    def ChangeSets.latest_id(changesets_dir)
      ChangeSets.ids(changesets_dir)[-1]
    end

  private

    def to_rss(title, link, description, message_linker, change_linker)
      raise "title" unless title
      raise "link" unless link
      raise "description" unless description
      raise "message_linker" unless message_linker
      raise "change_linker" unless change_linker

      RSS::Maker.make("2.0") do |rss|
        rss.channel.title = title
        rss.channel.link = link
        rss.channel.description = description
        rss.channel.generator = "RSCM - Ruby Source Control Management"

        changesets.each do |changeset|
          item = rss.items.new_item
          
          item.pubDate = changeset.time
          item.author = changeset.developer
          item.title = changeset.message
          item.link = change_linker.changeset_url(changeset, true)
          item.description = "<b>#{changeset.developer}</b><br/>\n"
          item.description << message_linker.highlight(changeset.message).gsub(/\n/, "<br/>\n") << "<p/>\n"
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
    include XMLRPC::Marshallable

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
      raise "time must be a Time object - it was a #{t.class.name} with the string value #{t}" unless t.is_a?(Time)
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
    
    def save(changesets_dir)
      changesets_file = "#{changesets_dir}/#{id}/changesets.yaml"
      FileUtils.mkdir_p(File.dirname(changesets_file))
      File.open(changesets_file, "w") do |io|
        YAML::dump(self, io)
      end
    end
    
    # Returns the id of the changeset or +time+ in ymdHMS format if undefined.
    def id
      @revision || @time.ymdHMS
    end
  end

  class Change
    include XMLRPC::Marshallable

    MODIFIED = "MODIFIED"
    DELETED = "DELETED"
    ADDED = "ADDED"
    MOVED = "MOVED"
    
    ICONS = {
      MODIFIED => "/images/16x16/document_edit.png",
      DELETED => "/images/16x16/document_delete.png",
      ADDED => "/images/16x16/document_add.png",
      MOVED => "/images/16x16/document_exchange.png",
    }
    
    attr_accessor :status
    attr_accessor :path
    attr_accessor :previous_revision
    attr_accessor :revision

    # TODO: Remove redundant attributes that are in ChangeSet
    attr_accessor :developer
    attr_accessor :message
    # This is a UTC ruby time
    attr_accessor :time
    
    def initialize(path=nil, developer=nil, message=nil, revision=nil, time=nil, status=DELETED)
      @path, @developer, @message, @revision, @time, @status = path, developer, message, revision, time, status
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
    
    def icon
      ICONS[@status] || "/images/16x16/document_warning.png"
    end

  end

end
