require 'erb'
require 'xmlrpc/utils'
require 'pebbles/TimeUtils'
require 'pebbles/Matchable'

module DamageControl

    # TODO: change this so it looks similar to SVN's log output, which is nice.
    CHANGESET_TEXT_FORMAT = <<EOF
MAIN:<%= developer %>:<%= time.utc.strftime("%Y%m%d%H%M%S") %>
<%= developer%>
<%= time.utc.strftime("%d %B %Y %H:%M:%S UTC") %> (<%= time_difference %> ago)
<%= message %>
----<% each do |change| %>
<%= change.path %> <%= change.revision %><% end %>
EOF

  class ChangeSets
    include XMLRPC::Marshallable
    include Pebbles::Matchable

    attr_reader :changesets

    def initialize()
      @changesets = []
    end

    def [](change)
      @changesets[change]
    end

    def each(&block)
      @changesets.each(&block)
    end
    
    def length
      @changesets.length
    end

    def ==(other)
      @changesets == other.changesets
    end

    # adds a Change or a ChangeSet
    # if the argument is a Change and no corresponding ChangeSet exist,
    # then a new ChangeSet is created, added, and the Change is added to that ChangeSet -
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
          changeset.developer = change_or_changeset.developer
          changeset.message = change_or_changeset.message
          changeset.time = change_or_changeset.time
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
    
    def format(template, format_time=Time.new.utc)
      result = ""
      each { |changeset| result << changeset.format(template, format_time) << "\n" }
      result
    end

  end

  class ChangeSet
    include XMLRPC::Marshallable
    include Pebbles::Matchable

    attr_reader :changes
    attr_accessor :revision
    attr_accessor :developer
    attr_accessor :message
    attr_accessor :time

    def initialize()
      @changes = []
    end
    
    def << (change)
      @changes << change
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
    
    def ==(other)
      @changes == other.changes
    end

    def can_contain?(change)
      self.developer == change.developer &&
      self.message == change.message
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
      "#{revision} | #{developer} | #{time}"
    end
  end

  class Change
    include XMLRPC::Marshallable
    include Pebbles::Matchable
    
    MODIFIED = "MODIFIED"
    DELETED = "DELETED"
    ADDED = "ADDED"
    MOVED = "MOVED"
    
    def initialize(path="", developer="", message="", revision="", time="")
      @path, @developer, @message, @revision, @time = path, developer, message, revision, time
    end
  
    def to_s
      "#{path} #{developer} #{revision} #{time}"
    end
  
    attr_accessor :status
    attr_accessor :developer
    attr_accessor :message
    attr_accessor :path
    attr_accessor :previous_revision
    attr_accessor :revision
    # This is a UTC ruby time
    attr_accessor :time
    
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

    def ==(change)
      self.path == change.path &&
      self.developer == change.developer &&
      self.message == change.message &&
      self.revision == change.revision &&
      self.time == change.time
    end

  end

end