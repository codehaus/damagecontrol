module RSCM
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
    attr_accessor :previous_native_revision_identifier
    # The native SCM's revision for this file. For non-transactional SCMs this is different from
    # the parent Revision's 
    attr_accessor :native_revision_identifier

    # TODO: Remove redundant attributes that are in Revision
    attr_accessor :developer
    attr_accessor :message
    # This is a UTC ruby time
    attr_accessor :time
    
    def initialize(path=nil, status=nil, developer=nil, message=nil, native_revision_identifier=nil, time=nil)
      @path, @developer, @message, @native_revision_identifier, @time, @status = path, developer, message, native_revision_identifier, time, status
    end
  
    def accept(visitor)
      visitor.visit_file(self)
    end

    def to_s
      "#{path} | #{native_revision_identifier}"
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

    def native_revision_identifier=(id)
      raise "can't be null" if id.nil?
      @native_revision_identifier = id
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
      self.native_revision_identifier == other.native_revision_identifier &&
      self.time == other.time
    end
    
  end
end