require 'rscm'
require 'time'
require 'stringio'
require 'rexml/document'

module RSCM
  class DarcsLogParser
    def parse_changesets(io, from_identifier=Time.epoch, to_identifier=Time.infinity)
      changesets = ChangeSets.new

      doc = REXML::Document.new(io)

      path_revisions = {}
      doc.elements.each("//patch") do |element|
        changeset = parse_changeset(element.to_s, path_revisions)
        if ((from_identifier <= changeset.time) && (changeset.time <= to_identifier))
          changesets.add(changeset)
        end
      end

      changesets.each do |changeset|
        changeset.each do |change|
          current_index = path_revisions[change.path].index(change.revision)
          change.previous_revision = path_revisions[change.path][current_index + 1]
        end
      end

      changesets
    end

    def parse_changeset(changeset_io, path_revisions)
      changeset = ChangeSet.new

      doc = REXML::Document.new(changeset_io)

      doc.elements.each("patch") do |element|
        changeset.revision = element.attributes['hash']
        changeset.developer = element.attributes['author']
        changeset.time = Time.parse(element.attributes['local_date'])
        changeset.message = element.elements["comment"].text
        changeset.message.lstrip!
        changeset.message.rstrip!
      

        element.elements["summary"].elements.each("add_file") { |file|
          add_changes(changeset, file.text.strip, Change::ADDED, path_revisions)
        }
        element.elements["summary"].elements.each("modify_file") { |file|
          add_changes(changeset, file.text.strip, Change::MODIFIED, path_revisions)
        }
      end

      changeset
    end

  private

    def add_changes(changeset, path, state, path_revisions)
      changeset << Change.new(path, state, changeset.developer, nil, changeset.revision, changeset.time)

      path_revisions[path] ||= []
      path_revisions[path] << changeset.revision
    end
  end
end

