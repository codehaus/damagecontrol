require 'rscm'
require 'time'
require 'stringio'

module RSCM

  class MonotoneLogParser
  
    def parse_revisions(io, from_identifier=Time.epoch, to_identifier=Time.infinity)
      # skip first separator
      io.readline
      
      all_revisions = []
      revision_string = ""
      
      # hash of path => [array of revisions]
      path_revisions = {}
      io.each_line do |line|
        if(line =~ /-----------------------------------------------------------------/)
          revision = parse_revision(StringIO.new(revision_string), path_revisions)
          all_revisions << revision
          revision_string = ""
        else
          revision_string << line
        end
      end
      revision = parse_revision(StringIO.new(revision_string), path_revisions)
      all_revisions << revision
      
      # Filter out the revisions and set the previous revisions, knowing that most recent is at index 0.

      from_time = time(all_revisions, from_identifier, Time.epoch)
      to_time = time(all_revisions, to_identifier, Time.infinity)

      revisions = Revisions.new

      all_revisions.each do |revision|
        if((from_time < revision.time) && (revision.time <= to_time))
          revisions.add(revision)
          revision.each do |change|
            current_index = path_revisions[change.path].index(change.revision)
            change.previous_revision = path_revisions[change.path][current_index + 1]
          end
        end
      end
      revisions
    end
    
    def parse_revision(revision_io, path_revisions)
      revision = Revision.new
      state = nil
      revision_io.each_line do |line|
        if(line =~ /^Revision: (.*)$/ && revision.revision.nil?)
          revision.revision = $1
        elsif(line =~ /^Author: (.*)$/ && revision.developer.nil?)
          revision.developer = $1
        elsif(line =~ /^Date: (.*)$/ && revision.time.nil?)
          revision.time = Time.utc(
            $1[0..3].to_i,
            $1[5..6].to_i,
            $1[8..9].to_i,
            $1[11..12].to_i,
            $1[14..15].to_i,
            $1[17..18].to_i
          )
        elsif(line =~ /^ChangeLog:\s*$/ && revision.message.nil?)
          state = :message
        elsif(state == :message && revision.message.nil?)
          revision.message = ""
        elsif(state == :message && revision.message)
          revision.message << line
        elsif(line =~ /^Added files:\s*$/)
          state = :added
        elsif(state == :added)
          add_changes(revision, line, RevisionFile::ADDED, path_revisions)
        elsif(line =~ /^Modified files:\s*$/)
          state = :modified
        elsif(state == :modified)
          add_changes(revision, line, RevisionFile::MODIFIED, path_revisions)
        end
      end
      revision.message.chomp! rescue revision.message = ''
      revision
    end
    
  private

    def time(revisions, identifier, default)
      cs = revisions.find do |revision|
        revision.identifier == identifier
      end
      cs ? cs.time : (identifier.is_a?(Time) ? identifier : default)
    end

    def add_changes(revision, line, state, path_revisions)
      paths = line.split(" ")
      paths.each do |path|
        revision << RevisionFile.new(path, state, revision.developer, nil, revision.revision, revision.time)

        # now record path revisions so we can keep track of previous rev for each path
        # doesn't work for moved files, and have no idea how to make it work either.
        path_revisions[path] ||= [] 
        path_revisions[path] << revision.revision
      end
      
    end
  end

end
