module DamageControl

  class ChangeSet < Array
    def developer
      self[0].developer
    end

    def message
      self[0].message
    end

    def time
      self[0].time
    end
  end

  class Change
    def initialize(path="", developer="", message="", revision="", time="")
      self.path, self.developer, self.message, self.revision, self.time = 
        path, developer, message, revision, time
    end
  
    attr_accessor :path
    attr_accessor :developer
    attr_accessor :message
    attr_accessor :revision
    attr_accessor :previous_revision
    # This is an UTC ruby time
    attr_accessor :time
    
    def message=(message)
      raise "can't be null" if message.nil?
      @message = message
    end

    def developer=(developer)
      raise "can't be null" if developer.nil?
      @developer = developer
    end
  end

  module ChangeUtils
    def changes_within_period(changes, from_time, end_time)
      changes_within_period = []
      last_change = nil
      changes.each do |change|
        above = end_time - change.time
        below = change.time - from_time
        if(0 <= above && 0 <= below)
          changes_within_period << change
          last_change = change
        end
        # find the previous revision
        if(last_change && (last_change.path == change.path) && (last_change.revision != change.revision) && last_change.previous_revision.nil?)
          last_change.previous_revision = change.revision
        end
      end
      changes_within_period
    end

    def convert_changes_to_changesets(changes)
      changesets = []
      changes.each do |change|
        with_matching_changeset(changesets, change) do |changeset|
          changeset << change
          changesets << changeset unless changesets.index(changeset)
        end
      end
      changesets
    end

  private

    def with_matching_changeset(changesets, change)
      matching_changeset = nil
      changesets.each do |changeset|
        # consider match if developer and message is same
        if(changeset.developer == change.developer && changeset.message == change.message)
          matching_changeset = changeset
        end
      end
      if matching_changeset.nil?
        matching_changeset = ChangeSet.new 
      end
      yield matching_changeset
    end
  end

end