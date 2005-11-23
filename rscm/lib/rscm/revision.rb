require 'rscm/time_ext'
require 'rscm/revision_file'

module RSCM

  # A collection of Revision.
  class Revisions
    include Enumerable

    attr_accessor :revisions

    def initialize(revisions=[])
      @revisions = revisions
    end
    
    # Accepts a visitor that will receive callbacks while
    # iterating over this instance's internal structure.
    # The visitor should respond to the following methods:
    #
    # * visit_revisions(revisions)
    # * visit_revision(revision)
    # * visit_file(file)
    #
    def accept(visitor)
      visitor.visit_revisions(self)
      self.each{|revision| revision.accept(visitor)}
    end

    def [](file)
      @revisions[file]
    end

    def each(&block)
      @revisions.each(&block)
    end
    
    def reverse
      r = clone
      r.revisions = @revisions.dup.reverse
      r
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
    def add(file_or_revision)
      if(file_or_revision.is_a?(Revision))
        @revisions << file_or_revision
        return file_or_revision
      else
        revision = @revisions.find { |a_revision| a_revision.can_contain?(file_or_revision) }
        if(revision.nil?)
          revision = Revision.new
          @revisions << revision
          revision << file_or_revision
          return revision
        end
        revision << file_or_revision
        return nil
      end
    end
    
    def push(*file_or_revisions)
      file_or_revisions.each { |file_or_revision| self << (file_or_revision) }
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

    attr_reader :files
    attr_accessor :identifier
    attr_accessor :developer
    attr_accessor :message
    attr_accessor :time

    def initialize(files=[])
      @files = files
    end
    
    def accept(visitor)
      visitor.visit_revision(self)
      @files.each{|file| file.accept(visitor)}
    end

    def << (file)
      @files << file
      if(self.time.nil? || self.time < file.time unless file.time.nil?)
        self.time = file.time
        self.identifier = self.time if(self.identifier.nil? || self.identifier.is_a?(Time))
      end
      self.developer = file.developer if file.developer
      self.message = file.message if file.message
    end

    def [] (index)
      @files[index]
    end

    # Iterates over all the RevisionFile objects
    def each(&block)
      @files.each(&block)
    end
    
    def pop
      @files.pop
    end
    
    def length
      @files.length
    end
    alias :size :length

    def time=(t)
      raise "time must be a Time object - it was a #{t.class.name} with the string value #{t}" unless t.is_a?(Time)
      raise "can't set time to an inferiour value than the previous value" if @time && (t < @time)
      @time = t
    end
    
    def ==(other)
      other.is_a?(self.class) && @files == other.files
    end

    def <=>(other)
      @time <=> other.time
    end

    # Whether this instance can contain a File. Used
    # by non-transactional SCMs.
    def can_contain?(file) #:nodoc:
      self.developer == file.developer &&
      self.message == file.message &&
      (self.time - file.time).abs < 60
    end

    # String representation that can be used for debugging.
    def to_s
      result = "#{identifier} | #{developer} | #{time} | #{message}\n"
      self.each do |file|
        result << " " << file.to_s << "\n"
      end
      result
    end
    
  end

end
