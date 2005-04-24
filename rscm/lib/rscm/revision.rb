require 'xmlrpc/utils'
require 'rscm/time_ext'

module RSCM

  # A collection of Revision.
  class Revisions
    include Enumerable
    include XMLRPC::Marshallable

    attr_reader :revisions

    def initialize(revisions=[])
      @revisions = revisions
    end
    
    # Accepts a visitor that will receive callbacks while
    # iterating over this instance's internal structure.
    # The visitor should respond to the following methods:
    #
    # * visit_revisions(revisions)
    # * visit_revision(revision)
    # * visit_file(change)
    #
    def accept(visitor)
      visitor.visit_revisions(self)
      self.each{|revision| revision.accept(visitor)}
    end

    def [](change)
      @revisions[change]
    end

    def each(&block)
      @revisions.each(&block)
    end
    
    def reverse
      Revisions.new(@revisions.dup.reverse)
    end
    
    def length
      @revisions.length
    end

    def ==(other)
      return false if !other.is_a?(self.class)
      @revisions == other.revisions
    end
    
    def empty?
      @revisions.empty?
    end
    
    # The set of developers that contributed to all of the contained Revision s.
    def developers
      result = []
      each do |revision|
        result << revision.developer unless result.index(revision.developer)
      end
      result
    end
    
    # The latest Revision (with the latest time)
    # or nil if there are none.
    def latest
      result = nil
      each do |revision|
        result = revision if result.nil? || result.time < revision.time
      end
      result
    end

    # Adds a File or a Revision.
    # If the argument is a File and no corresponding Revision exists,
    # a new Revision is created, added, and the File is added to that Revision -
    # and then finally the newly created Revision is returned.
    # Otherwise nil is returned.
    def add(change_or_revision)
      if(change_or_revision.is_a?(Revision))
        @revisions << change_or_revision
        return change_or_revision
      else
        revision = @revisions.find { |a_revision| a_revision.can_contain?(change_or_revision) }
        if(revision.nil?)
          revision = Revision.new
          @revisions << revision
          revision << change_or_revision
          return revision
        end
        revision << change_or_revision
        return nil
      end
    end
    
    def push(*change_or_revisions)
      change_or_revisions.each { |change_or_revision| self << (change_or_revision) }
      self
    end

    # Sorts the revisions according to time
    def sort!
      @revisions.sort!
      self
    end

  end

  # Represents a collection of File that were committed at the same time.
  # Non-transactional SCMs (such as CVS and StarTeam) emulate Revision
  # by grouping File s that were committed by the same developer, with the
  # same commit message, and within a "reasonably" small timespan.
  class Revision
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
    
    def accept(visitor)
      visitor.visit_revision(self)
      @changes.each{|change| change.accept(visitor)}
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

    def <=>(other)
      @time <=> other.time
    end

    # Whether this instance can contain a File. Used
    # by non-transactional SCMs.
    def can_contain?(change)
      self.developer == change.developer &&
      self.message == change.message &&
      (self.time - change.time).abs < 60
    end

    # String representation that can be used for debugging.
    def to_s
      result = "#{revision} | #{developer} | #{time} | #{message}\n"
      self.each do |change|
        result << " " << change.to_s << "\n"
      end
      result
    end
    
    # Returns the identifier of the revision. This is the revision 
    # (if defined) or an UTC time if it is not natively supported by the scm.
    def identifier
      @revision || @time
    end
    
  end

  # Represents a file within a Revision, and also information about how this file
  # was modified compared with the previous revision.
  class RevisionFile
    include XMLRPC::Marshallable

    MODIFIED = "MODIFIED"
    DELETED = "DELETED"
    ADDED = "ADDED"
    MOVED = "MOVED"
    
    attr_accessor :status
    attr_accessor :path
    attr_accessor :previous_revision
    attr_accessor :revision

    # TODO: Remove redundant attributes that are in Revision
    attr_accessor :developer
    attr_accessor :message
    # This is a UTC ruby time
    attr_accessor :time
    
    def initialize(path=nil, status=nil, developer=nil, message=nil, revision=nil, time=nil)
      @path, @developer, @message, @revision, @time, @status = path, developer, message, revision, time, status
    end
  
    def accept(visitor)
      visitor.visit_file(self)
    end

    def to_s
      "#{path} | #{revision}"
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
