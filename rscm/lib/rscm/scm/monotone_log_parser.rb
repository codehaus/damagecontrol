require 'rscm'
require 'time'
require 'stringio'

module RSCM

  class MonotoneLogParser
  
    def parse_changesets(io, from_identifier=Time.epoch, to_identifier=Time.infinity)
      # skip first separator
      io.readline
      
      changesets = ChangeSets.new
      changeset_string = ""
      io.each_line do |line|
        if(line =~ /-----------------------------------------------------------------/)
          changeset = parse_changeset(StringIO.new(changeset_string))
          changesets.add(changeset)
          changeset_string = ""
        else
          changeset_string << line
        end
      end
      changeset = parse_changeset(StringIO.new(changeset_string))
      if((from_identifier <= changeset.time) && (changeset.time <= to_identifier))
        changesets.add(changeset)
      end
      changesets
    end

    def parse_changeset(changeset_io)
      changeset = ChangeSet.new
      state = nil
      changeset_io.each_line do |line|
        if(line =~ /^Revision: (.*)$/ && changeset.revision.nil?)
          changeset.revision = $1
        elsif(line =~ /^Author: (.*)$/ && changeset.developer.nil?)
          changeset.developer = $1
        elsif(line =~ /^Date: (.*)$/ && changeset.time.nil?)
          changeset.time = Time.utc(
            $1[0..3].to_i,
            $1[5..6].to_i,
            $1[8..9].to_i,
            $1[11..12].to_i,
            $1[14..15].to_i,
            $1[17..18].to_i
          )
        elsif(line =~ /^ChangeLog:$/ && changeset.message.nil?)
          state = :message
        elsif(state == :message && changeset.message.nil?)
          changeset.message = ""
        elsif(state == :message && changeset.message)
          changeset.message << line
        elsif(line =~ /^Added files:$/)
          state = :added
        elsif(state == :added)
          add_changes(changeset, line, Change::ADDED)
        elsif(line =~ /^Modified files:$/)
          state = :modified
        elsif(state == :modified)
          add_changes(changeset, line, Change::MODIFIED)
        end
      end
      changeset.message.chomp!
      raise "No time:\n{changeset}" unless changeset.time
      changeset
    end
    
  private

    def add_changes(changeset, line, state)
      paths = line.split(" ")
      paths.each do |path|
        changeset << Change.new(path, state)
      end
    end
  end

end
