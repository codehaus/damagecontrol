require 'rscm'
require 'time'
require 'stringio'

module RSCM

  class MonotoneLogParser
  
    def parse_changesets(io, from_identifier=Time.epoch, to_identifier=Time.infinity)
      # skip first separator
      io.readline
      
      all_changesets = []
      changeset_string = ""
      
      # hash of path => [array of revisions]
      path_revisions = {}
      io.each_line do |line|
        if(line =~ /-----------------------------------------------------------------/)
          changeset = parse_changeset(StringIO.new(changeset_string), path_revisions)
          all_changesets << changeset
          changeset_string = ""
        else
          changeset_string << line
        end
      end
      changeset = parse_changeset(StringIO.new(changeset_string), path_revisions)
      all_changesets << changeset
      
      # Filter out the changesets and set the previous revisions, knowing that most recent is at index 0.

      from_time = time(all_changesets, from_identifier, Time.epoch)
      to_time = time(all_changesets, to_identifier, Time.infinity)

      changesets = ChangeSets.new

      all_changesets.each do |changeset|
        if((from_time < changeset.time) && (changeset.time <= to_time))
          changesets.add(changeset)
          changeset.each do |change|
            current_index = path_revisions[change.path].index(change.revision)
            change.previous_revision = path_revisions[change.path][current_index + 1]
          end
        end
      end
      changesets
    end
    
    def parse_changeset(changeset_io, path_revisions)
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
        elsif(line =~ /^ChangeLog:\s*$/ && changeset.message.nil?)
          state = :message
        elsif(state == :message && changeset.message.nil?)
          changeset.message = ""
        elsif(state == :message && changeset.message)
          changeset.message << line
        elsif(line =~ /^Added files:\s*$/)
          state = :added
        elsif(state == :added)
          add_changes(changeset, line, Change::ADDED, path_revisions)
        elsif(line =~ /^Modified files:\s*$/)
          state = :modified
        elsif(state == :modified)
          add_changes(changeset, line, Change::MODIFIED, path_revisions)
        end
      end
      changeset.message.chomp!
      changeset
    end
    
  private

    def time(changesets, identifier, default)
      cs = changesets.find do |changeset|
        changeset.identifier == identifier
      end
      cs ? cs.time : (identifier.is_a?(Time) ? identifier : default)
    end

    def add_changes(changeset, line, state, path_revisions)
      paths = line.split(" ")
      paths.each do |path|
        changeset << Change.new(path, state, changeset.developer, nil, changeset.revision, changeset.time)

        # now record path revisions so we can keep track of previous rev for each path
        # doesn't work for moved files, and have no idea how to make it work either.
        path_revisions[path] ||= [] 
        path_revisions[path] << changeset.revision
      end
      
    end
  end

end
